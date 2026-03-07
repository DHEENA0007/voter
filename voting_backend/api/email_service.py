"""
Email notification service for the Secure Voting System.
Handles sending emails for voter approval, voter ID delivery,
corrections, elections, and system updates.
"""

import logging
from django.core.mail import send_mail, EmailMultiAlternatives
from django.template.loader import render_to_string
from django.conf import settings
from django.utils import timezone

logger = logging.getLogger(__name__)


def _log_email(recipient_email, recipient_name, notification_type, subject, body, success=True, error_message=None):
    """Log email to the EmailNotification model."""
    from .models import EmailNotification
    try:
        EmailNotification.objects.create(
            recipient_email=recipient_email,
            recipient_name=recipient_name,
            notification_type=notification_type,
            subject=subject,
            body=body,
            success=success,
            error_message=error_message,
        )
    except Exception as e:
        logger.error(f"Failed to log email notification: {e}")


def send_voter_approved_email(voter):
    """
    Send email to voter when their application is approved.
    Includes their Voter ID and login instructions.
    """
    subject = '✅ Your Voter Application Has Been Approved!'
    
    html_body = f"""
    <html>
    <body style="font-family: 'Segoe UI', Arial, sans-serif; background-color: #f5f7fa; margin: 0; padding: 0;">
        <div style="max-width: 600px; margin: 30px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08);">
            <!-- Header -->
            <div style="background: linear-gradient(135deg, #1a237e, #283593); padding: 32px; text-align: center;">
                <h1 style="color: #FFD600; margin: 0; font-size: 28px;">🗳️ Secure Voting System</h1>
                <p style="color: rgba(255,255,255,0.85); margin-top: 8px; font-size: 14px;">Your Vote, Your Voice</p>
            </div>
            
            <!-- Body -->
            <div style="padding: 32px;">
                <h2 style="color: #1a237e; margin-top: 0;">Congratulations, {voter.full_name}! 🎉</h2>
                <p style="color: #555; line-height: 1.6;">
                    Your voter registration application has been <strong style="color: #2e7d32;">approved</strong> by the admin. 
                    You are now eligible to participate in elections.
                </p>
                
                <!-- Voter ID Card -->
                <div style="background: linear-gradient(135deg, #e8eaf6, #f5f5f5); border-radius: 12px; padding: 24px; margin: 20px 0; border-left: 4px solid #1a237e;">
                    <h3 style="color: #1a237e; margin-top: 0; font-size: 14px; text-transform: uppercase; letter-spacing: 1px;">Your Voter Credentials</h3>
                    <table style="width: 100%; border-collapse: collapse;">
                        <tr>
                            <td style="padding: 8px 0; color: #888; font-size: 13px;">Voter ID:</td>
                            <td style="padding: 8px 0; font-weight: bold; color: #1a237e; font-size: 18px; letter-spacing: 1px;">{voter.voter_id}</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; color: #888; font-size: 13px;">Full Name:</td>
                            <td style="padding: 8px 0; font-weight: 600; color: #333;">{voter.full_name}</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; color: #888; font-size: 13px;">Father/Husband:</td>
                            <td style="padding: 8px 0; color: #333;">{voter.father_name or 'N/A'}</td>
                        </tr>
                        <tr>
                            <td style="padding: 8px 0; color: #888; font-size: 13px;">Date of Birth:</td>
                            <td style="padding: 8px 0; color: #333;">{voter.date_of_birth}</td>
                        </tr>
                    </table>
                </div>
                
                <!-- Login Instructions -->
                <div style="background: #fff3e0; border-radius: 12px; padding: 20px; margin: 20px 0;">
                    <h4 style="color: #e65100; margin-top: 0;">🔐 How to Login</h4>
                    <ol style="color: #555; line-height: 1.8;">
                        <li>Open the Secure Voting App</li>
                        <li>Select <strong>"Login as Voter"</strong></li>
                        <li>Enter your <strong>Voter ID: {voter.voter_id}</strong></li>
                        <li>Enter the <strong>passcode</strong> you set during registration</li>
                    </ol>
                </div>
                
                <p style="color: #888; font-size: 12px; margin-top: 24px;">
                    ⚠️ Keep your Voter ID and passcode safe. Do not share them with anyone.
                </p>
            </div>
            
            <!-- Footer -->
            <div style="background: #f5f7fa; padding: 20px 32px; text-align: center; border-top: 1px solid #e0e0e0;">
                <p style="color: #999; font-size: 12px; margin: 0;">
                    Secure Mobile Biometric Voting System © {timezone.now().year}
                </p>
            </div>
        </div>
    </body>
    </html>
    """
    
    plain_body = f"""
Congratulations, {voter.full_name}!

Your voter registration application has been APPROVED.

Your Voter Credentials:
- Voter ID: {voter.voter_id}
- Full Name: {voter.full_name}
- Father/Husband: {voter.father_name or 'N/A'}
- Date of Birth: {voter.date_of_birth}

How to Login:
1. Open the Secure Voting App
2. Select "Login as Voter"
3. Enter your Voter ID: {voter.voter_id}
4. Enter the passcode you set during registration

Keep your Voter ID and passcode safe. Do not share them with anyone.

Secure Mobile Biometric Voting System
"""

    try:
        msg = EmailMultiAlternatives(
            subject=subject,
            body=plain_body,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[voter.email],
        )
        msg.attach_alternative(html_body, "text/html")
        msg.send(fail_silently=False)
        
        _log_email(voter.email, voter.full_name, 'voter_approved', subject, plain_body)
        logger.info(f"Approval email sent to {voter.email}")
        return True
    except Exception as e:
        _log_email(voter.email, voter.full_name, 'voter_approved', subject, plain_body, 
                   success=False, error_message=str(e))
        logger.error(f"Failed to send approval email to {voter.email}: {e}")
        return False


def send_voter_rejected_email(voter, reason=''):
    """Send email to voter when their application is rejected."""
    subject = '❌ Your Voter Application Status Update'
    
    html_body = f"""
    <html>
    <body style="font-family: 'Segoe UI', Arial, sans-serif; background-color: #f5f7fa; margin: 0; padding: 0;">
        <div style="max-width: 600px; margin: 30px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08);">
            <div style="background: linear-gradient(135deg, #1a237e, #283593); padding: 32px; text-align: center;">
                <h1 style="color: #FFD600; margin: 0; font-size: 28px;">🗳️ Secure Voting System</h1>
            </div>
            <div style="padding: 32px;">
                <h2 style="color: #c62828; margin-top: 0;">Application Not Approved</h2>
                <p style="color: #555; line-height: 1.6;">
                    Dear <strong>{voter.full_name}</strong>,<br><br>
                    We regret to inform you that your voter registration application has been 
                    <strong style="color: #c62828;">rejected</strong>.
                </p>
                {f'<div style="background: #ffebee; border-radius: 12px; padding: 20px; margin: 20px 0;"><h4 style="color: #c62828; margin-top: 0;">Reason:</h4><p style="color: #555;">{reason}</p></div>' if reason else ''}
                <p style="color: #555; line-height: 1.6;">
                    If you believe this is an error, please contact the election commission or re-apply with correct information.
                </p>
            </div>
            <div style="background: #f5f7fa; padding: 20px 32px; text-align: center; border-top: 1px solid #e0e0e0;">
                <p style="color: #999; font-size: 12px; margin: 0;">Secure Mobile Biometric Voting System © {timezone.now().year}</p>
            </div>
        </div>
    </body>
    </html>
    """
    
    plain_body = f"Dear {voter.full_name},\n\nYour voter registration application has been rejected.\n{f'Reason: {reason}' if reason else ''}\n\nIf you believe this is an error, please contact the election commission.\n"

    try:
        msg = EmailMultiAlternatives(subject, plain_body, settings.DEFAULT_FROM_EMAIL, [voter.email])
        msg.attach_alternative(html_body, "text/html")
        msg.send(fail_silently=False)
        _log_email(voter.email, voter.full_name, 'voter_rejected', subject, plain_body)
        return True
    except Exception as e:
        _log_email(voter.email, voter.full_name, 'voter_rejected', subject, plain_body,
                   success=False, error_message=str(e))
        logger.error(f"Failed to send rejection email to {voter.email}: {e}")
        return False


def send_correction_status_email(correction, status):
    """Send email when a voter's correction request status changes."""
    voter = correction.voter
    
    if status == 'approved':
        subject = '✅ Your Voter Card Correction Has Been Approved!'
        status_text = 'approved and applied'
        color = '#2e7d32'
    else:
        subject = '❌ Your Voter Card Correction Request Update'
        status_text = 'rejected'
        color = '#c62828'

    html_body = f"""
    <html>
    <body style="font-family: 'Segoe UI', Arial, sans-serif; background-color: #f5f7fa; margin: 0; padding: 0;">
        <div style="max-width: 600px; margin: 30px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08);">
            <div style="background: linear-gradient(135deg, #1a237e, #283593); padding: 32px; text-align: center;">
                <h1 style="color: #FFD600; margin: 0; font-size: 28px;">🗳️ Secure Voting System</h1>
            </div>
            <div style="padding: 32px;">
                <h2 style="color: {color}; margin-top: 0;">Correction Request {status_text.title()}</h2>
                <p style="color: #555; line-height: 1.6;">
                    Dear <strong>{voter.full_name}</strong>,<br><br>
                    Your voter card correction request has been <strong style="color: {color};">{status_text}</strong>.
                </p>
                
                <div style="background: #f5f5f5; border-radius: 12px; padding: 20px; margin: 20px 0;">
                    <h4 style="color: #333; margin-top: 0;">Correction Details:</h4>
                    <p style="color: #555; margin: 4px 0;">Requested Name: <strong>{correction.requested_full_name}</strong></p>
                    {f'<p style="color: #555; margin: 4px 0;">Requested Father Name: <strong>{correction.requested_father_name}</strong></p>' if correction.requested_father_name else ''}
                    {f'<p style="color: #555; margin: 4px 0;">Admin Notes: <em>{correction.admin_notes}</em></p>' if correction.admin_notes else ''}
                </div>
                
                {'<p style="color: #555;">Your voter card has been updated with the corrected information.</p>' if status == 'approved' else '<p style="color: #555;">If you have questions, please contact the election commission.</p>'}
            </div>
            <div style="background: #f5f7fa; padding: 20px 32px; text-align: center; border-top: 1px solid #e0e0e0;">
                <p style="color: #999; font-size: 12px; margin: 0;">Secure Mobile Biometric Voting System © {timezone.now().year}</p>
            </div>
        </div>
    </body>
    </html>
    """

    plain_body = f"Dear {voter.full_name},\n\nYour voter card correction request has been {status_text}.\n\nRequested Name: {correction.requested_full_name}\n"

    try:
        msg = EmailMultiAlternatives(subject, plain_body, settings.DEFAULT_FROM_EMAIL, [voter.email])
        msg.attach_alternative(html_body, "text/html")
        msg.send(fail_silently=False)
        notification_type = 'correction_approved' if status == 'approved' else 'correction_rejected'
        _log_email(voter.email, voter.full_name, notification_type, subject, plain_body)
        return True
    except Exception as e:
        notification_type = 'correction_approved' if status == 'approved' else 'correction_rejected'
        _log_email(voter.email, voter.full_name, notification_type, subject, plain_body,
                   success=False, error_message=str(e))
        logger.error(f"Failed to send correction email to {voter.email}: {e}")
        return False


def send_new_election_email(election, voters=None):
    """
    Send email notification about a new/live election to all approved voters.
    If voters is None, sends to all approved voters.
    """
    from .models import Voter
    
    if voters is None:
        voters = Voter.objects.filter(status='approved').exclude(email='').exclude(email__isnull=True)
    
    subject = f'🗳️ New Election: {election.name}'
    
    success_count = 0
    fail_count = 0
    
    for voter in voters:
        html_body = f"""
        <html>
        <body style="font-family: 'Segoe UI', Arial, sans-serif; background-color: #f5f7fa; margin: 0; padding: 0;">
            <div style="max-width: 600px; margin: 30px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08);">
                <div style="background: linear-gradient(135deg, #1a237e, #283593); padding: 32px; text-align: center;">
                    <h1 style="color: #FFD600; margin: 0; font-size: 28px;">🗳️ Secure Voting System</h1>
                </div>
                <div style="padding: 32px;">
                    <h2 style="color: #1a237e; margin-top: 0;">New Election Announcement!</h2>
                    <p style="color: #555; line-height: 1.6;">
                        Dear <strong>{voter.full_name}</strong>,<br><br>
                        A new election has been announced. Please login to cast your vote!
                    </p>
                    
                    <div style="background: linear-gradient(135deg, #e8eaf6, #f5f5f5); border-radius: 12px; padding: 24px; margin: 20px 0; border-left: 4px solid #FFD600;">
                        <h3 style="color: #1a237e; margin-top: 0;">{election.name}</h3>
                        <p style="color: #555; margin: 4px 0;">{election.description}</p>
                        <table style="width: 100%; border-collapse: collapse; margin-top: 12px;">
                            <tr>
                                <td style="padding: 6px 0; color: #888; font-size: 13px;">Start Date:</td>
                                <td style="padding: 6px 0; font-weight: 600; color: #333;">{election.start_date.strftime('%B %d, %Y %I:%M %p')}</td>
                            </tr>
                            <tr>
                                <td style="padding: 6px 0; color: #888; font-size: 13px;">End Date:</td>
                                <td style="padding: 6px 0; font-weight: 600; color: #333;">{election.end_date.strftime('%B %d, %Y %I:%M %p')}</td>
                            </tr>
                            <tr>
                                <td style="padding: 6px 0; color: #888; font-size: 13px;">Status:</td>
                                <td style="padding: 6px 0; font-weight: 600; color: #2e7d32;">{election.status.upper()}</td>
                            </tr>
                        </table>
                    </div>
                    
                    <div style="text-align: center; margin: 24px 0;">
                        <p style="color: #1a237e; font-weight: 600; font-size: 16px;">
                            Login to the Secure Voting App and cast your vote!
                        </p>
                    </div>
                </div>
                <div style="background: #f5f7fa; padding: 20px 32px; text-align: center; border-top: 1px solid #e0e0e0;">
                    <p style="color: #999; font-size: 12px; margin: 0;">Secure Mobile Biometric Voting System © {timezone.now().year}</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        plain_body = f"Dear {voter.full_name},\n\nA new election has been announced: {election.name}\n\n{election.description}\n\nStart: {election.start_date}\nEnd: {election.end_date}\n\nPlease login to the Secure Voting App to cast your vote.\n"

        try:
            msg = EmailMultiAlternatives(subject, plain_body, settings.DEFAULT_FROM_EMAIL, [voter.email])
            msg.attach_alternative(html_body, "text/html")
            msg.send(fail_silently=False)
            _log_email(voter.email, voter.full_name, 'new_election', subject, plain_body)
            success_count += 1
        except Exception as e:
            _log_email(voter.email, voter.full_name, 'new_election', subject, plain_body,
                       success=False, error_message=str(e))
            fail_count += 1
            logger.error(f"Failed to send election email to {voter.email}: {e}")
    
    return {'sent': success_count, 'failed': fail_count}


def send_registration_confirmation_email(voter):
    """Send confirmation email after a voter submits their registration."""
    subject = '📋 Voter Registration Received - Pending Approval'
    
    html_body = f"""
    <html>
    <body style="font-family: 'Segoe UI', Arial, sans-serif; background-color: #f5f7fa; margin: 0; padding: 0;">
        <div style="max-width: 600px; margin: 30px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08);">
            <div style="background: linear-gradient(135deg, #1a237e, #283593); padding: 32px; text-align: center;">
                <h1 style="color: #FFD600; margin: 0; font-size: 28px;">🗳️ Secure Voting System</h1>
                <p style="color: rgba(255,255,255,0.85); margin-top: 8px; font-size: 14px;">Your Vote, Your Voice</p>
            </div>
            <div style="padding: 32px;">
                <h2 style="color: #1a237e; margin-top: 0;">Registration Received! 📝</h2>
                <p style="color: #555; line-height: 1.6;">
                    Dear <strong>{voter.full_name}</strong>,<br><br>
                    Thank you for submitting your voter registration application. 
                    Your application is currently <strong style="color: #f57c00;">pending review</strong> by the admin.
                </p>
                
                <div style="background: #fff3e0; border-radius: 12px; padding: 20px; margin: 20px 0;">
                    <h4 style="color: #e65100; margin-top: 0;">⏳ What's Next?</h4>
                    <ul style="color: #555; line-height: 1.8;">
                        <li>Your application is being reviewed by the admin</li>
                        <li>You will receive an email once your application is processed</li>
                        <li>Once approved, you'll receive your <strong>Voter ID</strong> via email</li>
                        <li>You can then login using your Voter ID and passcode</li>
                    </ul>
                </div>
                
                <p style="color: #888; font-size: 12px; margin-top: 24px;">
                    This is an automated email. Please do not reply.
                </p>
            </div>
            <div style="background: #f5f7fa; padding: 20px 32px; text-align: center; border-top: 1px solid #e0e0e0;">
                <p style="color: #999; font-size: 12px; margin: 0;">Secure Mobile Biometric Voting System © {timezone.now().year}</p>
            </div>
        </div>
    </body>
    </html>
    """
    
    plain_body = f"Dear {voter.full_name},\n\nThank you for submitting your voter registration.\nYour application is pending review by the admin.\n\nYou will receive an email once your application is processed.\n"

    try:
        msg = EmailMultiAlternatives(subject, plain_body, settings.DEFAULT_FROM_EMAIL, [voter.email])
        msg.attach_alternative(html_body, "text/html")
        msg.send(fail_silently=False)
        _log_email(voter.email, voter.full_name, 'general', subject, plain_body)
        return True
    except Exception as e:
        _log_email(voter.email, voter.full_name, 'general', subject, plain_body,
                   success=False, error_message=str(e))
        logger.error(f"Failed to send registration confirmation to {voter.email}: {e}")
        return False
