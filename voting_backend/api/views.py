"""
API Views for the Secure Mobile Biometric Voting System.
"""

import hashlib
import random
import string
from django.utils import timezone
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.contrib.auth.hashers import check_password, make_password
from django.db.models import Sum
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser

from .models import Voter, Election, Party, Candidate, Vote, VoterCorrection
from .serializers import (
    VoterRegistrationSerializer, VoterSerializer, VoterLoginSerializer,
    BiometricLoginSerializer, AdminLoginSerializer, ElectionSerializer,
    PartySerializer, CandidateSerializer, CandidateResultSerializer,
    VoteCastSerializer, VoteSerializer, DashboardSerializer,
    ElectionResultSerializer, UserSerializer, VoterCorrectionSerializer
)


# ============================================================
# Authentication Views
# ============================================================

@api_view(['POST'])
@permission_classes([AllowAny])
def admin_login(request):
    """Admin login with username and password."""
    serializer = AdminLoginSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    user = authenticate(
        username=serializer.validated_data['username'],
        password=serializer.validated_data['password']
    )

    if user is None:
        return Response(
            {'error': 'Invalid credentials'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    if not user.is_staff:
        return Response(
            {'error': 'Not authorized as admin'},
            status=status.HTTP_403_FORBIDDEN
        )

    token, _ = Token.objects.get_or_create(user=user)
    return Response({
        'token': token.key,
        'user': UserSerializer(user).data,
        'role': 'admin',
        'message': 'Admin login successful'
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def voter_login(request):
    """Voter login with Voter ID + Passcode."""
    serializer = VoterLoginSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    try:
        voter = Voter.objects.get(voter_id=serializer.validated_data['voter_id'])
    except Voter.DoesNotExist:
        return Response(
            {'error': 'Invalid Voter ID'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    if not check_password(serializer.validated_data['passcode'], voter.passcode):
        return Response(
            {'error': 'Invalid passcode'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    if voter.status != 'approved':
        status_messages = {
            'pending': 'Your application is still pending approval.',
            'rejected': 'Your application has been rejected.',
            'blocked': 'Your account has been blocked.',
        }
        return Response(
            {'error': status_messages.get(voter.status, 'Account not active')},
            status=status.HTTP_403_FORBIDDEN
        )

    # Create or get user for token auth
    user, created = User.objects.get_or_create(
        username=f"voter_{voter.voter_id}",
        defaults={'first_name': voter.full_name}
    )
    if created:
        voter.user = user
        voter.save()

    token, _ = Token.objects.get_or_create(user=user)
    return Response({
        'token': token.key,
        'voter': VoterSerializer(voter).data,
        'role': 'voter',
        'message': 'Login successful'
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def biometric_login(request):
    """Biometric login - device verifies fingerprint, sends voter_id + biometric_token."""
    serializer = BiometricLoginSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    try:
        voter = Voter.objects.get(voter_id=serializer.validated_data['voter_id'])
    except Voter.DoesNotExist:
        return Response(
            {'error': 'Invalid Voter ID'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    if voter.status != 'approved':
        return Response(
            {'error': 'Account not approved'},
            status=status.HTTP_403_FORBIDDEN
        )

    if not voter.biometric_enabled:
        return Response(
            {'error': 'Biometric login not enabled for this account'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Verify biometric token (device-level verification happened on mobile)
    if voter.biometric_token and voter.biometric_token != serializer.validated_data['biometric_token']:
        return Response(
            {'error': 'Biometric verification failed'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    user, created = User.objects.get_or_create(
        username=f"voter_{voter.voter_id}",
        defaults={'first_name': voter.full_name}
    )
    if created:
        voter.user = user
        voter.save()

    token, _ = Token.objects.get_or_create(user=user)
    return Response({
        'token': token.key,
        'voter': VoterSerializer(voter).data,
        'role': 'voter',
        'message': 'Biometric login successful'
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def voter_register(request):
    """Voter self-registration (Apply as Voter)."""
    serializer = VoterRegistrationSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    voter = serializer.save()
    return Response({
        'message': 'Registration submitted successfully. Please wait for admin approval.',
        'voter': VoterSerializer(voter).data
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def enable_biometric(request):
    """Enable biometric login for a voter."""
    try:
        voter = Voter.objects.get(user=request.user)
    except Voter.DoesNotExist:
        return Response({'error': 'Voter profile not found'}, status=status.HTTP_404_NOT_FOUND)

    biometric_token = request.data.get('biometric_token')
    if not biometric_token:
        return Response({'error': 'Biometric token required'}, status=status.HTTP_400_BAD_REQUEST)

    voter.biometric_enabled = True
    voter.biometric_token = biometric_token
    voter.save()

    return Response({'message': 'Biometric login enabled successfully'})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """Logout - delete token."""
    try:
        request.user.auth_token.delete()
    except Exception:
        pass
    return Response({'message': 'Logged out successfully'})


# ============================================================
# Admin Dashboard
# ============================================================

@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_dashboard(request):
    """Get admin dashboard statistics."""
    data = {
        'total_voters': Voter.objects.count(),
        'approved_voters': Voter.objects.filter(status='approved').count(),
        'pending_approvals': Voter.objects.filter(status='pending').count(),
        'rejected_voters': Voter.objects.filter(status='rejected').count(),
        'blocked_voters': Voter.objects.filter(status='blocked').count(),
        'total_elections': Election.objects.count(),
        'live_elections': Election.objects.filter(status='live').count(),
        'upcoming_elections': Election.objects.filter(status='upcoming').count(),
        'closed_elections': Election.objects.filter(status='closed').count(),
        'total_votes_cast': Vote.objects.count(),
    }
    serializer = DashboardSerializer(data)
    return Response(serializer.data)


# ============================================================
# Voter Management (Admin)
# ============================================================

class VoterManagementViewSet(viewsets.ModelViewSet):
    """Admin viewset for managing voters."""
    queryset = Voter.objects.all()
    serializer_class = VoterSerializer
    permission_classes = [IsAdminUser]

    def get_queryset(self):
        queryset = Voter.objects.all()
        status_filter = self.request.query_params.get('status', None)
        search = self.request.query_params.get('search', None)

        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if search:
            queryset = queryset.filter(
                full_name__icontains=search
            ) | queryset.filter(
                voter_id__icontains=search
            ) | queryset.filter(
                mobile_number__icontains=search
            )
        return queryset

    def create(self, request, *args, **kwargs):
        """Admin creates a voter (auto-approved)."""
        serializer = VoterRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        voter = serializer.save(status='approved')
        
        # Generate unique Voter ID
        if not voter.voter_id:
            prefix = "VAL"
            suffix = ''.join(random.choices(string.digits, k=6))
            voter.voter_id = f"{prefix}{suffix}"
            while Voter.objects.filter(voter_id=voter.voter_id).exists():
                suffix = ''.join(random.choices(string.digits, k=6))
                voter.voter_id = f"{prefix}{suffix}"
            voter.save()

        return Response(
            VoterSerializer(voter).data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve a voter application."""
        voter = self.get_object()
        if voter.status != 'pending':
            return Response(
                {'error': f'Cannot approve voter with status: {voter.status}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Generate unique Voter ID on approval
        if not voter.voter_id:
            prefix = "VAL"
            suffix = ''.join(random.choices(string.digits, k=6))
            voter.voter_id = f"{prefix}{suffix}"
            while Voter.objects.filter(voter_id=voter.voter_id).exists():
                suffix = ''.join(random.choices(string.digits, k=6))
                voter.voter_id = f"{prefix}{suffix}"

        voter.status = 'approved'
        voter.save()
        return Response({
            'message': f'Voter {voter.full_name} approved successfully',
            'voter_id': voter.voter_id
        })

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject a voter application."""
        voter = self.get_object()
        voter.status = 'rejected'
        voter.save()
        return Response({'message': f'Voter {voter.full_name} rejected'})

    @action(detail=True, methods=['post'])
    def block(self, request, pk=None):
        """Block a voter."""
        voter = self.get_object()
        voter.status = 'blocked'
        voter.save()
        return Response({'message': f'Voter {voter.full_name} blocked'})

    @action(detail=True, methods=['post'])
    def unblock(self, request, pk=None):
        """Unblock a voter."""
        voter = self.get_object()
        voter.status = 'approved'
        voter.save()
        return Response({'message': f'Voter {voter.full_name} unblocked'})

    @action(detail=False, methods=['post'])
    def remove_duplicates(self, request):
        """Remove duplicate voter entries based on Voter ID."""
        from django.db.models import Count
        duplicates = (Voter.objects
                      .values('voter_id')
                      .annotate(count=Count('id'))
                      .filter(count__gt=1))
        removed = 0
        for dup in duplicates:
            voters = Voter.objects.filter(voter_id=dup['voter_id']).order_by('created_at')
            for v in voters[1:]:
                v.delete()
                removed += 1
        return Response({'message': f'Removed {removed} duplicate voters'})


# ============================================================
# Election Management (Admin)
# ============================================================

class ElectionViewSet(viewsets.ModelViewSet):
    """Viewset for election management."""
    queryset = Election.objects.all()
    serializer_class = ElectionSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]
        return [IsAdminUser()]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        """Start an election (set status to live)."""
        election = self.get_object()
        if election.status == 'live':
            return Response({'error': 'Election is already live'}, status=status.HTTP_400_BAD_REQUEST)
        if election.status == 'closed':
            return Response({'error': 'Cannot restart a closed election'}, status=status.HTTP_400_BAD_REQUEST)
        election.status = 'live'
        election.save()
        return Response({'message': f'Election "{election.name}" is now live'})

    @action(detail=True, methods=['post'])
    def stop(self, request, pk=None):
        """Stop an election (set status to closed)."""
        election = self.get_object()
        if election.status != 'live':
            return Response({'error': 'Only live elections can be stopped'}, status=status.HTTP_400_BAD_REQUEST)
        election.status = 'closed'
        election.save()
        return Response({'message': f'Election "{election.name}" has been closed'})

    @action(detail=True, methods=['post'])
    def extend(self, request, pk=None):
        """Extend election end date."""
        election = self.get_object()
        new_end_date = request.data.get('end_date')
        if not new_end_date:
            return Response({'error': 'New end date required'}, status=status.HTTP_400_BAD_REQUEST)
        election.end_date = new_end_date
        election.save()
        return Response({'message': f'Election extended to {new_end_date}'})

    @action(detail=True, methods=['get'])
    def results(self, request, pk=None):
        """Get election results."""
        election = self.get_object()
        candidates = election.candidates.all().order_by('-votes_count')
        total_votes = election.votes.count()
        total_approved_voters = Voter.objects.filter(status='approved').count()
        participation_rate = (total_votes / total_approved_voters * 100) if total_approved_voters > 0 else 0

        winner = candidates.first() if candidates.exists() and total_votes > 0 else None

        return Response({
            'election': ElectionSerializer(election).data,
            'candidates': CandidateResultSerializer(candidates, many=True).data,
            'winner': CandidateResultSerializer(winner).data if winner else None,
            'total_votes': total_votes,
            'participation_rate': round(participation_rate, 2),
        })

    @action(detail=True, methods=['post'])
    def publish_results(self, request, pk=None):
        """Publish election results."""
        election = self.get_object()
        if election.status != 'closed':
            return Response({'error': 'Only closed elections can have results published'}, status=status.HTTP_400_BAD_REQUEST)
        election.result_published = True
        election.save()
        return Response({'message': 'Results published successfully'})

    @action(detail=True, methods=['get'])
    def monitoring(self, request, pk=None):
        """Real-time election monitoring data."""
        election = self.get_object()
        total_approved = Voter.objects.filter(status='approved').count()
        total_voted = election.votes.count()
        participation = (total_voted / total_approved * 100) if total_approved > 0 else 0

        candidates_data = []
        for candidate in election.candidates.all():
            candidates_data.append({
                'id': candidate.id,
                'name': candidate.name,
                'party': candidate.party.name,
                'votes': candidate.votes_count,
            })

        return Response({
            'election_name': election.name,
            'status': election.status,
            'total_approved_voters': total_approved,
            'total_votes_cast': total_voted,
            'participation_percentage': round(participation, 2),
            'candidates': candidates_data,
        })


# ============================================================
# Party Management (Admin)
# ============================================================

class PartyViewSet(viewsets.ModelViewSet):
    """Viewset for party management."""
    queryset = Party.objects.all()
    serializer_class = PartySerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]
        return [IsAdminUser()]


# ============================================================
# Candidate Management (Admin)
# ============================================================

class CandidateViewSet(viewsets.ModelViewSet):
    """Viewset for candidate management."""
    queryset = Candidate.objects.all()
    serializer_class = CandidateSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]
        return [IsAdminUser()]

    def get_queryset(self):
        queryset = Candidate.objects.all()
        election_id = self.request.query_params.get('election', None)
        if election_id:
            queryset = queryset.filter(election_id=election_id)
        return queryset


# ============================================================
# Voting (Voter)
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def cast_vote(request):
    """Cast a vote - requires authenticated voter."""
    serializer = VoteCastSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    # Get voter profile
    try:
        voter = Voter.objects.get(user=request.user)
    except Voter.DoesNotExist:
        return Response(
            {'error': 'Voter profile not found'},
            status=status.HTTP_404_NOT_FOUND
        )

    if voter.status != 'approved':
        return Response(
            {'error': 'Your account is not approved for voting'},
            status=status.HTTP_403_FORBIDDEN
        )

    # Get election
    try:
        election = Election.objects.get(id=serializer.validated_data['election_id'])
    except Election.DoesNotExist:
        return Response(
            {'error': 'Election not found'},
            status=status.HTTP_404_NOT_FOUND
        )

    if election.status != 'live':
        return Response(
            {'error': 'This election is not currently active'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Check if already voted
    if Vote.objects.filter(voter=voter, election=election).exists():
        return Response(
            {'error': 'You have already voted in this election'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Get candidate
    try:
        candidate = Candidate.objects.get(
            id=serializer.validated_data['candidate_id'],
            election=election
        )
    except Candidate.DoesNotExist:
        return Response(
            {'error': 'Candidate not found in this election'},
            status=status.HTTP_404_NOT_FOUND
        )

    # Cast vote
    vote_hash = hashlib.sha256(
        f"{voter.voter_id}-{election.id}-{candidate.id}-{timezone.now().isoformat()}".encode()
    ).hexdigest()

    vote = Vote.objects.create(
        voter=voter,
        election=election,
        candidate=candidate,
        vote_hash=vote_hash
    )

    # Update vote counts
    candidate.votes_count += 1
    candidate.save()
    election.total_votes += 1
    election.save()

    return Response({
        'message': 'Vote cast successfully!',
        'vote_hash': vote_hash,
        'election': election.name,
        'candidate': candidate.name,
    }, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_vote_status(request, election_id):
    """Check if the current voter has already voted in an election."""
    try:
        voter = Voter.objects.get(user=request.user)
    except Voter.DoesNotExist:
        return Response({'error': 'Voter profile not found'}, status=status.HTTP_404_NOT_FOUND)

    has_voted = Vote.objects.filter(voter=voter, election_id=election_id).exists()
    return Response({'has_voted': has_voted})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def voter_profile(request):
    """Get current voter's profile."""
    try:
        voter = Voter.objects.get(user=request.user)
    except Voter.DoesNotExist:
        return Response({'error': 'Voter profile not found'}, status=status.HTTP_404_NOT_FOUND)
    return Response(VoterSerializer(voter).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def voter_elections(request):
    """Get elections available to the voter."""
    elections = Election.objects.filter(status__in=['live', 'closed'])
    data = []
    try:
        voter = Voter.objects.get(user=request.user)
    except Voter.DoesNotExist:
        return Response({'error': 'Voter profile not found'}, status=status.HTTP_404_NOT_FOUND)

    for election in elections:
        has_voted = Vote.objects.filter(voter=voter, election=election).exists()
        election_data = ElectionSerializer(election).data
        election_data['has_voted'] = has_voted
        data.append(election_data)

    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def election_results_voter(request, election_id):
    """Get election results for voter viewing (only if result published)."""
    try:
        election = Election.objects.get(id=election_id)
    except Election.DoesNotExist:
        return Response({'error': 'Election not found'}, status=status.HTTP_404_NOT_FOUND)

    if not election.result_published:
        return Response({'error': 'Results not yet published'}, status=status.HTTP_403_FORBIDDEN)

    candidates = election.candidates.all().order_by('-votes_count')
    total_votes = election.votes.count()
    winner = candidates.first() if candidates.exists() and total_votes > 0 else None

    return Response({
        'election': ElectionSerializer(election).data,
        'candidates': CandidateResultSerializer(candidates, many=True).data,
        'winner': CandidateResultSerializer(winner).data if winner else None,
        'total_votes': total_votes,
    })


class VoterCorrectionViewSet(viewsets.ModelViewSet):
    """Viewset for voter correction requests."""
    queryset = VoterCorrection.objects.all()
    serializer_class = VoterCorrectionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_staff:
            return VoterCorrection.objects.all()
        try:
            voter = Voter.objects.get(user=self.request.user)
            return VoterCorrection.objects.filter(voter=voter)
        except Voter.DoesNotExist:
            return VoterCorrection.objects.none()

    def perform_create(self, serializer):
        voter = Voter.objects.get(user=self.request.user)
        serializer.save(voter=voter)

    @action(detail=True, methods=['post'], permission_classes=[IsAdminUser])
    def approve(self, request, pk=None):
        correction = self.get_object()
        if correction.status != 'pending':
            return Response({'error': 'Correction already processed'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply the correction to the Voter record
        voter = correction.voter
        voter.full_name = correction.requested_full_name
        if correction.requested_father_name:
            voter.father_name = correction.requested_father_name
        voter.save()
        
        correction.status = 'approved'
        correction.save()
        return Response({'message': 'Correction approved and applied'})

    @action(detail=True, methods=['post'], permission_classes=[IsAdminUser])
    def reject(self, request, pk=None):
        correction = self.get_object()
        if correction.status != 'pending':
            return Response({'error': 'Correction already processed'}, status=status.HTTP_400_BAD_REQUEST)
        
        correction.status = 'rejected'
        correction.admin_notes = request.data.get('notes', '')
        correction.save()
        return Response({'message': 'Correction rejected'})


# ============================================================
# Health Check
# ============================================================

@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """API health check endpoint."""
    return Response({
        'status': 'healthy',
        'message': 'Secure Mobile Biometric Voting System API',
        'version': '1.0.0',
        'timestamp': timezone.now().isoformat(),
    })
