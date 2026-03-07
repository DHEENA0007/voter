"""
Serializers for the Secure Mobile Biometric Voting System API.
"""

from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth.hashers import make_password, check_password
from .models import Voter, Election, Party, Candidate, Vote, VoterCorrection


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'is_staff']


class VoterRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for voter self-registration."""

    class Meta:
        model = Voter
        fields = [
            'id', 'voter_id', 'full_name', 'father_name', 'date_of_birth', 'gender',
            'address', 'email', 'mobile_number', 'photo', 'passcode', 'status',
            'biometric_enabled', 'created_at'
        ]
        read_only_fields = ['id', 'status', 'created_at']
        extra_kwargs = {
            'passcode': {'write_only': True},
        }

    def create(self, validated_data):
        # Hash the passcode before saving
        validated_data['passcode'] = make_password(validated_data['passcode'])
        return super().create(validated_data)


class VoterSerializer(serializers.ModelSerializer):
    """Serializer for voter details (admin view)."""

    class Meta:
        model = Voter
        fields = [
            'id', 'voter_id', 'full_name', 'father_name', 'date_of_birth', 'gender',
            'address', 'email', 'mobile_number', 'photo', 'status',
            'biometric_enabled', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class VoterLoginSerializer(serializers.Serializer):
    """Serializer for voter login with Voter ID + Passcode."""
    voter_id = serializers.CharField(max_length=50)
    passcode = serializers.CharField(max_length=128)


class BiometricLoginSerializer(serializers.Serializer):
    """Serializer for biometric login."""
    voter_id = serializers.CharField(max_length=50)
    biometric_token = serializers.CharField(max_length=255)


class AdminLoginSerializer(serializers.Serializer):
    """Serializer for admin login."""
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(max_length=128)


class ElectionSerializer(serializers.ModelSerializer):
    """Serializer for elections."""
    candidates_count = serializers.SerializerMethodField()
    total_votes_cast = serializers.SerializerMethodField()

    class Meta:
        model = Election
        fields = [
            'id', 'name', 'description', 'start_date', 'end_date',
            'status', 'total_votes', 'result_published',
            'candidates_count', 'total_votes_cast',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'total_votes', 'created_at', 'updated_at']

    def get_candidates_count(self, obj):
        return obj.candidates.count()

    def get_total_votes_cast(self, obj):
        return obj.votes.count()


class PartySerializer(serializers.ModelSerializer):
    """Serializer for parties."""

    class Meta:
        model = Party
        fields = ['id', 'name', 'symbol', 'description', 'created_at']
        read_only_fields = ['id', 'created_at']


class CandidateSerializer(serializers.ModelSerializer):
    """Serializer for candidates."""
    party_name = serializers.CharField(source='party.name', read_only=True)
    party_symbol = serializers.ImageField(source='party.symbol', read_only=True)

    class Meta:
        model = Candidate
        fields = [
            'id', 'election', 'party', 'party_name', 'party_symbol',
            'name', 'photo', 'bio', 'votes_count', 'created_at'
        ]
        read_only_fields = ['id', 'votes_count', 'created_at']


class CandidateResultSerializer(serializers.ModelSerializer):
    """Serializer for candidate results (includes vote count)."""
    party_name = serializers.CharField(source='party.name', read_only=True)
    party_symbol = serializers.ImageField(source='party.symbol', read_only=True)
    vote_percentage = serializers.SerializerMethodField()

    class Meta:
        model = Candidate
        fields = [
            'id', 'name', 'party_name', 'party_symbol',
            'votes_count', 'vote_percentage', 'photo'
        ]

    def get_vote_percentage(self, obj):
        election = obj.election
        total = election.votes.count()
        if total == 0:
            return 0.0
        return round((obj.votes_count / total) * 100, 2)


class VoteCastSerializer(serializers.Serializer):
    """Serializer for casting a vote."""
    election_id = serializers.IntegerField()
    candidate_id = serializers.IntegerField()


class VoteSerializer(serializers.ModelSerializer):
    """Serializer for vote records."""
    voter_name = serializers.CharField(source='voter.full_name', read_only=True)
    candidate_name = serializers.CharField(source='candidate.name', read_only=True)
    election_name = serializers.CharField(source='election.name', read_only=True)

    class Meta:
        model = Vote
        fields = [
            'id', 'voter_name', 'election_name', 'candidate_name',
            'voted_at', 'vote_hash'
        ]
        read_only_fields = ['id', 'voted_at', 'vote_hash']


class DashboardSerializer(serializers.Serializer):
    """Serializer for admin dashboard statistics."""
    total_voters = serializers.IntegerField()
    approved_voters = serializers.IntegerField()
    pending_approvals = serializers.IntegerField()
    rejected_voters = serializers.IntegerField()
    blocked_voters = serializers.IntegerField()
    total_elections = serializers.IntegerField()
    live_elections = serializers.IntegerField()
    upcoming_elections = serializers.IntegerField()
    closed_elections = serializers.IntegerField()
    total_votes_cast = serializers.IntegerField()


class ElectionResultSerializer(serializers.Serializer):
    """Serializer for election results."""
    election = ElectionSerializer()
    candidates = CandidateResultSerializer(many=True)
    winner = CandidateResultSerializer(allow_null=True)
    total_votes = serializers.IntegerField()
    participation_rate = serializers.FloatField()


class VoterCorrectionSerializer(serializers.ModelSerializer):
    """Serializer for voter correction requests."""
    voter_name = serializers.CharField(source='voter.full_name', read_only=True)
    voter_id = serializers.CharField(source='voter.voter_id', read_only=True)

    class Meta:
        model = VoterCorrection
        fields = [
            'id', 'voter', 'voter_name', 'voter_id',
            'requested_full_name', 'requested_father_name',
            'status', 'admin_notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'voter', 'status', 'created_at', 'updated_at']
