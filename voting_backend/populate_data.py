import os
import django
import requests
from bs4 import BeautifulSoup
from django.core.files.base import ContentFile
import sys
from django.utils import timezone
from datetime import timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'api.settings')
django.setup()

from api.models import Party, Candidate, Election, User

def get_wiki_image(page_title):
    url = f"https://en.wikipedia.org/wiki/{page_title}"
    try:
        response = requests.get(url, headers={'User-Agent': 'Mozilla/5.0'})
        if response.status_code == 200:
            soup = BeautifulSoup(response.content, 'html.parser')
            infobox = soup.find('table', class_='infobox')
            if infobox:
                # Look for flag/logo first
                images = infobox.find_all('img')
                for img in images:
                    src = img.get('src', '').lower()
                    if 'flag' in src or 'logo' in src or '_symbol' in src:
                        img_url = img['src']
                        if img_url.startswith('//'):
                            return 'https:' + img_url
                        return img_url
                        
                # Fallback to first image
                img = infobox.find('img')
                if img:
                    img_url = img['src']
                    if img_url.startswith('//'):
                        return 'https:' + img_url
                    return img_url
    except Exception as e:
        pass
    return None

data = [
    {"party": "Communist Party of India", "party_query": "Communist_Party_of_India", "candidate": "D. Raja", "candidate_query": "D._Raja"},
    {"party": "Kongunadu Makkal Desia Katchi", "party_query": "Kongunadu_Makkal_Desia_Katchi", "candidate": "E. R. Eswaran", "candidate_query": "E._R._Eswaran"},
    {"party": "Tamil Maanila Congress (Moopanar)", "party_query": "Tamil_Maanila_Congress_(Moopanar)", "candidate": "G. K. Vasan", "candidate_query": "G._K._Vasan"},
    {"party": "Manithaneya Makkal Katchi", "party_query": "Manithaneya_Makkal_Katchi", "candidate": "M. H. Jawahirullah", "candidate_query": "M._H._Jawahirullah"},
    {"party": "Puthiya Tamilagam", "party_query": "Puthiya_Tamilagam", "candidate": "K. Krishnasamy", "candidate_query": "K._Krishnasamy"},
    {"party": "Indian Union Muslim League", "party_query": "Indian_Union_Muslim_League", "candidate": "K. M. Kader Mohideen", "candidate_query": "K._M._Kader_Mohideen"}
]

# Ensure there is an election to tie candidates to
start_date = timezone.now()
end_date = start_date + timedelta(days=30)
election, _ = Election.objects.get_or_create(
    name="General Elections 2024",
    defaults={
        "description": "National General Elections",
        "start_date": start_date,
        "end_date": end_date,
        "status": "live"
    }
)

for item in data:
    try:
        party_img_url = get_wiki_image(item['party_query'])
        cand_img_url = get_wiki_image(item['candidate_query'])
        
        party, created = Party.objects.get_or_create(name=item['party'])
        print(f"Party {party.name} {'created' if created else 'found'}.")
        
        if party_img_url and not party.symbol:
            img_resp = requests.get(party_img_url, headers={'User-Agent': 'Mozilla/5.0'})
            if img_resp.status_code == 200:
                file_name = f"{item['party_query']}_logo.png"
                party.symbol.save(file_name, ContentFile(img_resp.content), save=True)
                print(f"Added logo for {party.name}")
        
        candidate, created = Candidate.objects.get_or_create(
            election=election,
            party=party,
            defaults={"name": item['candidate']}
        )
        print(f"Candidate {candidate.name} {'created' if created else 'found'}.")
        
        if cand_img_url and not candidate.photo:
            img_resp = requests.get(cand_img_url, headers={'User-Agent': 'Mozilla/5.0'})
            if img_resp.status_code == 200:
                file_name = f"{item['candidate_query']}_photo.jpg"
                candidate.photo.save(file_name, ContentFile(img_resp.content), save=True)
                print(f"Added photo for {candidate.name}")
    except Exception as e:
        print(f"Error processing {item['party']}: {str(e)}")

print("Done population!")
