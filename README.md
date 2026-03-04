# BeautyPolisa - Kalkulator Składek OC

Interaktywny landing page oraz kalkulator ubezpieczeniowy dedykowany branży beauty (salony kosmetyczne, fryzjerskie, kosmetologiczne i podologiczne). Projekt stworzony we współpracy z BeautyRazem oraz obsługiwany przez Aura Consulting.

## 🚀 Główne funkcjonalności

* **Dynamiczny kalkulator ryzyka:** System automatycznie klasyfikuje salon do odpowiedniej taryfy na podstawie zaznaczonych zabiegów (4 grupy ryzyka).
* **Inteligentny cennik:** Składka jest przeliczana w czasie rzeczywistym z uwzględnieniem liczby pracowników oraz opcjonalnych rozszerzeń (np. Ochrona Prawna).
* **Obsługa wariantów specjalnych:** Automatyczne blokowanie standardowej wyceny i kierowanie do indywidualnej oceny ubezpieczyciela przy wyborze zabiegów wysokiego ryzyka (np. osocze, HIFU) lub dla dużych zespołów (powyżej 8 osób).
* **Generowanie Leadów:** Zintegrowane modale z formularzami (wniosek o polisę, szybki kontakt), które przesyłają ustrukturyzowane dane bezpośrednio przez Web3Forms.
* **Weryfikacja REGON:** Prosta, wizualna walidacja długości numeru rejestrowego firmy.
* **SEO & Analityka klasy Enterprise:** Wdrożone ustrukturyzowane dane Schema.org (Product, InsuranceAgency), tagi Open Graph oraz uniwersalne zdarzenia `dataLayer` gotowe pod integrację GTM (Meta Pixel, TikTok, Google Ads).

## 🛠️ Technologie

* **Frontend:** HTML5, Vanilla JavaScript
* **Styling:** Tailwind CSS (zoptymalizowany pod kompilację statyczną)
* **Mikrointerakcje:** Canvas-Confetti
* **Analityka:** Google Tag Manager (DataLayer push)
* **Wysyłka formularzy:** Web3Forms API

## 📦 Uruchomienie lokalne

1. Sklonuj repozytorium na swój dysk.
2. Upewnij się, że masz zainstalowane środowisko Node.js.
3. Zainstaluj zależności dla Tailwind CSS wpisując w terminalu: `npm install -D tailwindcss`.
4. Skompiluj style do statycznego pliku komendą: `npx tailwindcss -i ./input.css -o ./style.css --minify`.
5. Uruchom plik `index.html` w przeglądarce (zalecane użycie rozszerzenia Live Server).

## ⚙️ Konfiguracja formularzy

Projekt wykorzystuje darmowe API Web3Forms do obsługi zapytań bez konieczności utrzymywania backendu. 
* Odszukaj w pliku `index.html` ukryte pola formularzy: `<input type="hidden" name="access_key" value="TWÓJ_KLUCZ">`.
* Aby zmienić adres e-mail, na który trafiają leady, wygeneruj nowy klucz na stronie Web3Forms i podmień go w kodzie.

## 📄 Licencja

Projekt komercyjny. Wszelkie prawa zastrzeżone dla Aura Consulting / Program BeautyRazem 2026.
