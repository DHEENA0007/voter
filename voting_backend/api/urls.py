"""
URL patterns for the Secure Mobile Biometric Voting System API.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'voters', views.VoterManagementViewSet, basename='voter')
router.register(r'elections', views.ElectionViewSet, basename='election')
router.register(r'parties', views.PartyViewSet, basename='party')
router.register(r'candidates', views.CandidateViewSet, basename='candidate')
router.register(r'corrections', views.VoterCorrectionViewSet, basename='correction')

urlpatterns = [
    # Health Check
    path('health/', views.health_check, name='health-check'),

    # Authentication
    path('auth/admin/login/', views.admin_login, name='admin-login'),
    path('auth/voter/login/', views.voter_login, name='voter-login'),
    path('auth/voter/biometric-login/', views.biometric_login, name='biometric-login'),
    path('auth/voter/register/', views.voter_register, name='voter-register'),
    path('auth/voter/enable-biometric/', views.enable_biometric, name='enable-biometric'),
    path('auth/logout/', views.logout_view, name='logout'),

    # Admin Dashboard
    path('admin/dashboard/', views.admin_dashboard, name='admin-dashboard'),

    # Voting
    path('vote/cast/', views.cast_vote, name='cast-vote'),
    path('vote/status/<int:election_id>/', views.check_vote_status, name='vote-status'),

    # Voter Portal
    path('voter/profile/', views.voter_profile, name='voter-profile'),
    path('voter/elections/', views.voter_elections, name='voter-elections'),
    path('voter/results/<int:election_id>/', views.election_results_voter, name='voter-results'),

    # Router URLs
    path('', include(router.urls)),
]
