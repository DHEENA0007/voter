"""
Django signals for automatic cleanup of media files when models are deleted or updated.
Ensures that old files are removed from disk when a model with FileField/ImageField is deleted or when
the file is replaced with a new one.
"""

import os
from django.db.models.signals import pre_delete, pre_save
from django.dispatch import receiver
from .models import Voter, Party, Candidate


# ============================================================
# Auto-delete media files on model DELETE
# ============================================================

@receiver(pre_delete, sender=Voter)
def voter_delete_photo(sender, instance, **kwargs):
    """Delete voter photo file when voter is deleted."""
    if instance.photo:
        if os.path.isfile(instance.photo.path):
            try:
                os.remove(instance.photo.path)
            except (OSError, ValueError):
                pass


@receiver(pre_delete, sender=Party)
def party_delete_symbol(sender, instance, **kwargs):
    """Delete party symbol file when party is deleted."""
    if instance.symbol:
        try:
            if os.path.isfile(instance.symbol.path):
                os.remove(instance.symbol.path)
        except (OSError, ValueError):
            pass


@receiver(pre_delete, sender=Candidate)
def candidate_delete_photo(sender, instance, **kwargs):
    """Delete candidate photo file when candidate is deleted."""
    if instance.photo:
        try:
            if os.path.isfile(instance.photo.path):
                os.remove(instance.photo.path)
        except (OSError, ValueError):
            pass


# ============================================================
# Auto-delete OLD media files on model UPDATE (when file changes)
# ============================================================

@receiver(pre_save, sender=Voter)
def voter_update_photo(sender, instance, **kwargs):
    """Delete old voter photo when a new photo is uploaded."""
    if not instance.pk:
        return  # New instance, nothing to delete
    try:
        old = Voter.objects.get(pk=instance.pk)
    except Voter.DoesNotExist:
        return
    if old.photo and old.photo != instance.photo:
        try:
            if os.path.isfile(old.photo.path):
                os.remove(old.photo.path)
        except (OSError, ValueError):
            pass


@receiver(pre_save, sender=Party)
def party_update_symbol(sender, instance, **kwargs):
    """Delete old party symbol when a new symbol is uploaded."""
    if not instance.pk:
        return
    try:
        old = Party.objects.get(pk=instance.pk)
    except Party.DoesNotExist:
        return
    if old.symbol and old.symbol != instance.symbol:
        try:
            if os.path.isfile(old.symbol.path):
                os.remove(old.symbol.path)
        except (OSError, ValueError):
            pass


@receiver(pre_save, sender=Candidate)
def candidate_update_photo(sender, instance, **kwargs):
    """Delete old candidate photo when a new photo is uploaded."""
    if not instance.pk:
        return
    try:
        old = Candidate.objects.get(pk=instance.pk)
    except Candidate.DoesNotExist:
        return
    if old.photo and old.photo != instance.photo:
        try:
            if os.path.isfile(old.photo.path):
                os.remove(old.photo.path)
        except (OSError, ValueError):
            pass
