"""
Models for the Secure Mobile Biometric Voting System.
"""

import uuid
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class Voter(models.Model):
    """Voter model - stores voter registration details."""

    GENDER_CHOICES = [
        ('M', 'Male'),
        ('F', 'Female'),
        ('O', 'Other'),
    ]

    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('blocked', 'Blocked'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='voter_profile', null=True, blank=True)
    voter_id = models.CharField(max_length=50, unique=True, null=True, blank=True)
    full_name = models.CharField(max_length=200)
    father_name = models.CharField(max_length=200, null=True, blank=True)
    date_of_birth = models.DateField()
    gender = models.CharField(max_length=1, choices=GENDER_CHOICES)
    address = models.TextField()
    email = models.EmailField(max_length=254, blank=True, default='')
    mobile_number = models.CharField(max_length=15, unique=True)
    photo = models.ImageField(upload_to='voter_photos/', null=True, blank=True)
    passcode = models.CharField(max_length=128)  # Stored as hashed value
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    biometric_enabled = models.BooleanField(default=False)
    biometric_token = models.CharField(max_length=255, blank=True, null=True)  # For device-level biometric binding
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.full_name} ({self.voter_id})"


class Election(models.Model):
    """Election model - stores election details."""

    STATUS_CHOICES = [
        ('upcoming', 'Upcoming'),
        ('live', 'Live'),
        ('closed', 'Closed'),
    ]

    name = models.CharField(max_length=300)
    description = models.TextField(blank=True)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='upcoming')
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_elections')
    total_votes = models.PositiveIntegerField(default=0)
    result_published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.name

    @property
    def is_active(self):
        now = timezone.now()
        return self.status == 'live' and self.start_date <= now <= self.end_date


class Party(models.Model):
    """Party model - stores political party details."""

    name = models.CharField(max_length=200)
    symbol = models.ImageField(upload_to='party_symbols/', null=True, blank=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = 'Parties'
        ordering = ['name']

    def __str__(self):
        return self.name


class Candidate(models.Model):
    """Candidate model - stores candidate details for each election."""

    election = models.ForeignKey(Election, on_delete=models.CASCADE, related_name='candidates')
    party = models.ForeignKey(Party, on_delete=models.CASCADE, related_name='candidates')
    name = models.CharField(max_length=200)
    photo = models.ImageField(upload_to='candidate_photos/', null=True, blank=True)
    bio = models.TextField(blank=True)
    votes_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']
        unique_together = ['election', 'party']  # One candidate per party per election

    def __str__(self):
        return f"{self.name} - {self.party.name} ({self.election.name})"


class Vote(models.Model):
    """Vote model - stores individual votes. One vote per voter per election."""

    voter = models.ForeignKey(Voter, on_delete=models.CASCADE, related_name='votes')
    election = models.ForeignKey(Election, on_delete=models.CASCADE, related_name='votes')
    candidate = models.ForeignKey(Candidate, on_delete=models.CASCADE, related_name='votes')
    voted_at = models.DateTimeField(auto_now_add=True)
    vote_hash = models.CharField(max_length=64, unique=True)  # SHA256 hash for verification

    class Meta:
        unique_together = ['voter', 'election']  # One vote per voter per election
        ordering = ['-voted_at']

    def __str__(self):
        return f"{self.voter.full_name} → {self.candidate.name} ({self.election.name})"

    def save(self, *args, **kwargs):
        if not self.vote_hash:
            import hashlib
            raw = f"{self.voter.voter_id}-{self.election.id}-{self.candidate.id}-{timezone.now().isoformat()}"
            self.vote_hash = hashlib.sha256(raw.encode()).hexdigest()
        super().save(*args, **kwargs)


class VoterCorrection(models.Model):
    """Stores requests for correction of voter card details."""
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]

    voter = models.ForeignKey(Voter, on_delete=models.CASCADE, related_name='corrections')
    requested_full_name = models.CharField(max_length=200)
    requested_father_name = models.CharField(max_length=200, null=True, blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    admin_notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Correction for {self.voter.full_name} ({self.status})"


class EmailNotification(models.Model):
    """Tracks all email notifications sent by the system."""
    NOTIFICATION_TYPES = [
        ('voter_approved', 'Voter Approved'),
        ('voter_rejected', 'Voter Rejected'),
        ('voter_id_sent', 'Voter ID Sent'),
        ('correction_approved', 'Correction Approved'),
        ('correction_rejected', 'Correction Rejected'),
        ('new_election', 'New Election'),
        ('election_result', 'Election Result'),
        ('general', 'General Update'),
    ]

    recipient_email = models.EmailField()
    recipient_name = models.CharField(max_length=200)
    notification_type = models.CharField(max_length=30, choices=NOTIFICATION_TYPES)
    subject = models.CharField(max_length=500)
    body = models.TextField()
    sent_at = models.DateTimeField(auto_now_add=True)
    success = models.BooleanField(default=True)
    error_message = models.TextField(blank=True, null=True)

    class Meta:
        ordering = ['-sent_at']

    def __str__(self):
        return f"{self.notification_type} to {self.recipient_email} ({self.sent_at})"
