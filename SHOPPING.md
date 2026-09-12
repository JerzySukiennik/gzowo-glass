# Gzowo Glass — koszyk v1 (AliExpress, jedno zamówienie)

Ceny sprawdzone 2026-09-10 na pl.aliexpress.com (mogą się ruszać o kilka zł).
Ali ~120 zł, bateria z domu. Budżet 250 zł z dużym zapasem. Zamawia Jurek.

| # | Część | Link | Cena | Wariant do wybrania |
|---|---|---|---|---|
| 1 | **Seeed XIAO ESP32-S3 Sense** (mózg: kamera OV2640, mikrofon, 8 MB PSRAM, WiFi/BLE, ładowarka LiPo) | https://pl.aliexpress.com/item/1005006988111963.html | 65,59 zł | „1pc" (jeden wariant, kamera OV3660), dostawa 17–24 wrz |
| 2 | **OLED 0,96" 128×64 I2C SSD1306** (wyświetlacz do combinera) | https://pl.aliexpress.com/item/1005009170035050.html | 8,40 zł | kolor **niebieski**, 4-pin IIC, 1 szt. |
| 3 | **Beam splitter 30×30 mm** (półprzezroczyste lustro, combiner przed okiem) | https://pl.aliexpress.com/item/1005012046261289.html | 36,18 zł | 30×30 mm, 50/50 |
| 4 | **Soczewka Ø30 mm, f = 50 mm** (dwuwypukła, szkło) | https://pl.aliexpress.com/item/1005004213353520.html | ~3 zł | wariant **D30mm FL50mm** (25 mm nie ma w tym listingu; 30 jest OK) |
| 5 | **Wzmacniacz I2S MAX98357** (dźwięk z ESP32 do głośnika) | https://pl.aliexpress.com/item/1005009356741606.html | 5,51 zł | 1 szt. |
| 6 | **Głośnik 20 mm, 8 Ω, 1 W, ultracienki 3,6 mm** (2 szt. w paczce, zapas) | https://pl.aliexpress.com/item/1005009193787692.html | 3,84 zł | 20×3,6 mm |
| 7 | **LiPo 3,7 V, 300–1000 mAh — Z DOMU** (Ali nie wysyła ogniw do PL, Botland = płatna dostawa). Każde ogniwo 1S z drona/powerbanka/słuchawek; ważne: 1 cela 3,7 V, nie 7,4 V | — | 0 zł | jak nic nie znajdziesz: Botland Akyga 620 mAh 40×20×8 mm, 20,90 zł (AKU-15606) |
| 9 | **Mikroprzyciski 6×6 mm tact, 20 szt.** (przycisk na podzie) | https://pl.aliexpress.com/item/1005005845072975.html | 3,73 zł | 6×6×5 mm lub 6×6×7 mm |
| 10 | **Lusterka powierzchniowe (first surface mirror) 30×30 mm, 2 szt.** — jedno w podzie (składa wiązkę OLED→soczewka), drugie w daszku (zawraca wiązkę w dół na szybkę przed okiem) | szukaj na Ali: „first surface mirror 30x30" (~5–8 zł/szt.) | ~14 zł | 30×30, ≤ 2 mm grube, powierzchniowe (nie zwykłe lusterko łazienkowe — to daje podwójne odbicie) |
| | **Razem** | | **~137 zł** (samo Ali) | |

## Zanim klikniesz „kup"

- **Poz. 1 — zmiana 2026-09-10 wieczorem.** Pierwotny link (4000011805115, „45,49 zł") pokazywał domyślnie **samo złącze pinowe za 2,09 zł**, a dostawę 18 lis – 3 gru. Zastąpiony listingiem z jednym wariantem, 1000+ sprzedanych, dostawa w tydzień. Kamera OV3660 (2048×1536) zamiast OV2640 — dla nas tylko lepiej.
- **Sprawdzaj datę dostawy przy KAŻDEJ pozycji.** Ali sortuje po cenie z najtańszego wariantu (goldpiny, sam kabel, 1 szt. z partii), więc niska cena na liście nie znaczy niska cena tego, co chcemy. Zasada: po wybraniu wariantu cena i „Dostawa: …" mają wyglądać rozsądnie, inaczej szukaj innego sprzedawcy tego samego produktu.
- **Poz. 7, bateria — z domu.** Sprawdzone 2026-09-11: żaden LiPo z Ali nie wysyła do Polski, a Botland liczy za dostawę. Jurek szuka ogniwa w domu. Wymagania: **jedna cela Li-Po/Li-Ion 3,7 V** (na naklejce 3.7V, nie 7.4V), 300–1000 mAh, najlepiej płaski „pouch" do 9 mm grubości, z dwoma przewodami. Ogniwo 18650 też zadziała, tylko nie zmieści się w zauszniku — do testów na biurku ok.
- **Przewody:** zamiast silikonowych 28 AWG używamy starych jumperów F-F/M-M z uciętymi końcówkami (24–26 AWG, w v1 wystarczy). Pozycja usunięta z koszyka.
- **Poz. 3, beam splitter:** jeśli 36 zł boli, tańsza alternatywa to 50:50 K9 za 31,33 zł (https://pl.aliexpress.com/item/1005010313219927.html), ale sprawdź w opisie rozmiar — potrzebujemy min. 25×25 mm.
- **Głośnik:** najpierw sprawdź szufladę. Jeśli masz jakikolwiek 8 Ω, poz. 6 odpada (i tak 3,84 zł, więc zapas nie boli).

## Czego NIE zamawiamy z Ali (masz / robisz sam)

- **Ciemne „szkła" oprawki** — najtańsze okulary przeciwsłoneczne z Pepco/Action (5–10 zł) i wycinamy z nich soczewki pod wydruk. Kolor nieistotny, chodzi o kontrast HUD-u.
- **Filament** — X1C, PLA czarny albo matowy ciemnoszary.
- **Włącznik zasilania** — nie potrzebny: przytrzymanie przycisku = deep sleep. XIAO w deep sleep ciągnie tyle, że 500 mAh starcza na tygodnie czuwania.
- **Kabel USB-C** — do wgrywania firmware i ładowania, masz.

## Po dostawie — pierwszy test w 30 minut

1. XIAO + OLED (4 przewody: 3V3, GND, SDA→D4, SCL→D5) → wgrać test „Hello GLASS".
2. OLED + soczewka + beam splitter trzymane w ręku pod 45° → czy widać ostry napis „w powietrzu"? Odległość OLED↔soczewka ≈ 45–50 mm. To rozstrzyga geometrię oprawki zanim cokolwiek wydrukujemy.
