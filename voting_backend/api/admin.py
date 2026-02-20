"""
Django Admin registration for Voting System models.
"""

from django.contrib import admin
from .models import Voter, Election, Party, Candidate, Vote


@admin.register(Voter)
class VoterAdmin(admin.ModelAdmin):
    list_display = ['voter_id', 'full_name', 'mobile_number', 'status', 'created_at']
    list_filter = ['status', 'gender']
    search_fields = ['voter_id', 'full_name', 'mobile_number']
    list_editable = ['status']


@admin.register(Election)
class ElectionAdmin(admin.ModelAdmin):
    list_display = ['name', 'status', 'start_date', 'end_date', 'total_votes', 'result_published']
    list_filter = ['status', 'result_published']
    search_fields = ['name']


@admin.register(Party)
class PartyAdmin(admin.ModelAdmin):
    list_display = ['name', 'created_at']
    search_fields = ['name']


@admin.register(Candidate)
class CandidateAdmin(admin.ModelAdmin):
    list_display = ['name', 'party', 'election', 'votes_count']
    list_filter = ['election', 'party']
    search_fields = ['name']


@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    list_display = ['voter', 'election', 'candidate', 'voted_at']
    list_filter = ['election']
    readonly_fields = ['vote_hash']
