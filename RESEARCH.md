# Gzowo Glass — jak inni zbudowali DIY smart glasses (research 2026-09-11)

Siedem projektów, które robiły to samo co my. Co zrobili, co im nie wyszło i co z tego bierzemy.

## 1. E.D.I.T.H — AbrarFairuj, Instructables 2022 (ten od Jurka)
https://www.instructables.com/EDITH-How-Did-I-Build-a-Powerful-Smart-Glass-Under/

- **Sprzęt:** Raspberry Pi Zero (bez W!) + hub USB + dongle WiFi + dongle BT + mikrofon USB, OLED 0,96" I2C, głośnik z pinów PWM przez filtr RC + tranzystor, bateria 4000 mAh z modułem powerbanka. ~35 $.
- **Optyka:** OLED pod 22,5°, „szkło" (płaska szybka) pod 45°. **Bez soczewki.** Autor sam pisze, że użył płaskiego szkła, „żeby nie zmieniać rozmiaru obrazu" — efekt: oko musi ostrzyć na ekran z 3–5 cm, czego nie potrafi, więc obraz jest rozmyty. Dokładnie ten błąd omijamy soczewką.
- **Software:** Node na Pi, Dialogflow jako „AI", apka React Native na telefonie przesyła po Bluetooth pogodę/SMS/powiadomienia.
- **Sam przyznaje:** „bardzo duże, ciężkie, nie do noszenia", tydzień na samo postawienie OS-u, Pi Zero żre prąd (2000 mAh na chwilę). V2 „na własnej płytce z 8 rdzeniami" nigdy nie powstała.
- **Wniosek:** nasza decyzja XIAO zamiast Pi Zero i soczewka w torze to dokładnie naprawa jego dwóch największych problemów.

## 2. Arduino Glasses — Alain Mauer, hackaday.io (HMD do multimetru)
https://hackaday.io/project/12211-arduino-glasses-a-hmd-for-multimeter

- **Najlepiej policzona optyka z całej listy.** Soczewka plano-convex Ø30 mm, **f = 100 mm**, OLED **73 mm** od soczewki → obraz pozorny w odległości 27–30 cm, powiększenie 3×. Celowo 27–30 cm, bo to minimalna odległość, na którą oko ostrzy wygodnie.
- Lusterko pod 45°, uchwyt drukowany 3D. 0,96" OLED uznał za za duży, przeszedł na 0,49"/0,66" (chciał małe, my nie musimy).
- Arduino Pro Micro + HM-11 BLE, LiPo 280 mAh.
- **Problemy:** trudno kupić soczewkę (rozważał Fresnela), ekran odbijający wygiął się od ciepła, bez drukowanego uchwytu nie dało się utrzymać wyrównania.
- **Wniosek dla nas (liczby dla f = 50 mm):** OLED **bliżej niż ogniskowa** daje obraz pozorny w skończonej odległości:
  - 42 mm → obraz ~26 cm, powiększenie ~6× (OLED 22 mm szeroki wygląda jak ~14 cm na 26 cm, ~30° pola widzenia)
  - 45 mm → obraz ~45 cm, ~10×
  - 48 mm → obraz ~1,2 m
  - 50 mm → nieskończoność
  Uchwyt musi mieć **regulację 38–50 mm**, nie stałą pozycję. To potwierdza ryzyko z notatki projektu.

## 3. uGlass — moduł AR na okulary, hackaday.io
https://hackaday.io/project/167854-uglass-an-ar-module-on-your-glasses

- SSD1306 OLED + soczewka z Google Cardboard + **szkiełko mikroskopowe jako combiner**, hot glue na zwykłe okulary. nRF52832 + IMU.
- **Co się wysypało na Maker Faire:** pole widzenia za wąskie i zależne od położenia okularów na nosie („wielu ludzi nic nie widziało"); okrągła soczewka wystawała i **dotykała oka**.
- Ich wniosek: mniejszy ekran o większej gęstości pikseli, mniejsza soczewka, krótsza ogniskowa.
- **Wniosek dla nas:** soczewka jest nad okiem, nie przed nim — u nas nie dotknie oka. Combiner 30×30 mm zamiast szkiełka daje większe „okno". Oprawka drukowana na twarz Jurka zamiast klipsa = powtarzalne położenie.

## 4. Ochi — Harris Shallcross, Hackaday 2016 „why smart glasses are hard"
https://hackaday.com/2016/06/26/homemade-smart-glasses-shows-why-smart-glasses-are-hard/

- 0,95" 96×64 **kolorowy** OLED, soczewka z Cardboarda, **drukowany uchwyt przesuwany po drucianej szynie do regulacji ostrości**, STM32 + HM-11 BLE, Li-Ion + boost, apka Android.
- Lekcje: rozkład masy na głowie decyduje o komforcie; „wyświetlenie danych to połowa roboty, druga to CO i KIEDY pokazać".
- **Wniosek dla nas:** regulacja ostrości jako prowadnica z zaciskiem — bierzemy. Masa: bateria po tej samej stronie co elektronika obciąża jedno ucho; rozważyć baterię w lewym zauszniku jako przeciwwagę (kabel przez front).

## 5. Beady-i — XenonJohn, Instructables 2013
https://www.instructables.com/DIY-Google-Glasses-AKA-the-Beady-i/

- Nie DIY-optyka: przecięte gotowe okulary wideo Myvu Crystal + sprężysta opaska z headsetu. Inna droga niż nasza.
- Jedna przydatna uwaga: wyświetlacz da się ustawić bardzo blisko oka i nadal ostrzyć „na daleko", ale **za blisko = rzęsy uderzają w szkło przy mruganiu**. Combiner minimum ~20 mm od rogówki.

## 6. OpenGlass — BasedHardware (XIAO ESP32-S3 Sense, 20 $)
https://github.com/BasedHardware/OpenGlass · https://www.seeedstudio.com/blog/2024/05/23/openglass-turn-any-glasses-into-ai-smart-glasses-for-just-20-with-xiao-esp32s3-sense/

- **Ten sam moduł co nasz.** XIAO Sense + LiPo 250 mAh + drukowany klips na okulary. Zdjęcia i audio po **BLE do apki** (React Native/Expo), AI: Groq / OpenAI / Ollama moondream. Bez wyświetlacza.
- Repo zdeprecjonowane (projekt przeszedł w Omi), ale folder `firmware/` to gotowy szkic Arduino: kamera + mikrofon + BLE na XIAO Sense. Dobry punkt startowy do naszego firmware'u kamery.

## 7. Voice-Assistant-Camera-Wearable — xanderchinxyz
https://github.com/xanderchinxyz/Voice-Assistant-Camera-Wearable

- XIAO Sense, 220 mAh, drut dotykowy na D0 jako przycisk, BLE → Python na desktopie: VOSK (STT) → Groq (LLM+RAG) → pyttsx3 (TTS), moondream do obrazu. Bez wyświetlacza, bez głośnika w okularach.
- **Wniosek:** wszyscy na XIAO robią BLE do telefonu i mówią przez komputer. My idziemy krok dalej (WiFi + WebSocket + Gemini Live + HUD + głośnik w okularach) — nikt z tej listy tego nie połączył, ale każdy klocek osobno jest sprawdzony.

## Problemy powtarzające się w kilku projektach

- **Wypalanie OLED-a** po ~2 miesiącach codziennego statycznego UI → firmware: wygaszenie po ~10 s bezczynności, przesuwanie statycznych elementów o 1 px co kilka minut, jasność nie na maksa.
- **Wyrównanie optyki** to główna robota, nie elektronika. Każdy, kto nie miał drukowanego uchwytu, walczył z hot glue. Zasada: najpierw „klocki Lego" (OLED + soczewka + lusterko trzymane w ręku), dopiero potem CAD.
- **Pole widzenia** wąskie i wrażliwe na położenie na nosie → oprawka na miarę twarzy.
- **Waga i rozkład masy** — Pi Zero + 4000 mAh to koniec noszenia. XIAO + 500 mAh ≈ 25 g elektroniki.
- Audio przez BLE gubi pakiety przy odświeżaniu ekranu (u nas WiFi, nie dotyczy).
- Fresnel jako lekka alternatywa soczewki — jeśli szklana okaże się za ciężka/za gruba, opcja B.

## Co zmieniamy w planie po researchu

1. Uchwyt OLED z regulacją **38–50 mm** od soczewki (prowadnica + zacisk, jak Ochi), nie ±5 mm.
2. Combiner **≥ 20 mm** od oka (rzęsy), soczewka nad okiem nigdy w polu widzenia.
3. Firmware: **ochrona OLED** (wygaszanie, pixel shift, jasność ~60%).
4. Bateria rozważana w **lewym** zauszniku jako przeciwwaga.
5. Firmware kamery/mikrofonu na XIAO Sense: zacząć od szkicu z OpenGlass `firmware/`, nie od zera.
