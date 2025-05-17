\ ----- Połączenia linii i rejestrów -----
link l1:ct
link l2:rdm
link ra:0,1,2,z
link rb:8,9,10,z        \ podłączenie linii 8,9,10 z magistrali danych do rejestru RB
                        \ do [rb] można zapisywać
                        \ z [ra] można odczytywać

\ ----- Synonimy rejestrów -----
equ ax:r0               \ AX jako R0
equ cx:r1               \ CX jako R1
equ dx:r2               \ DX jako R2
equ bx:r3               \ BX jako R3
equ sp:r4               \ SP jako R4
equ bp:r5               \ BP jako R5
equ si:r6               \ SI jako R6
equ ddi:r7              \ DDI (zamiast DI - słowo kluczowe)
equ cs:r8               \ CS jako R8
equ ss:r9               \ SS jako R9
equ ds:r10              \ DS jako R10
equ es:r11              \ ES jako R11
equ ip:r12              \ IP jako R12
equ pom1:r13            \ rejestr pomocniczy 1
equ pom2:r14            \ rejestr pomocniczy 2
equ rr:r15              \ rejestr rozkazu

\ ----- Wartości początkowe rejestrów -----
accept cs:3456h         \ ustawienie CS
accept ip:0000h         \ ustawienie IP
accept cx:5678h         \ ustawienie CX
accept ax:F1A5h         \ ustawienie AX
accept bx:0024h         \ ustawienie BX
accept cx:0001h         \ ponowne ustawienie CX (korekta)
accept dx:0005h         \ ustawienie DX
accept ss:4457h         \ ustawienie SS (stos)
accept sp:0000h         \ ustawienie SP (stos)

\ ----- Kody rozkazów (LAB4, LAB3) -----
\ Rozkazy:
\ NOP        = 6E00h
\ DEC CX     = 4900h
\ POP DX     = 5A00h
\ XCHG AX/BX = 9000h
\ INC AX     = 4000h
\ PUSH BX    = 5300h
\ JC         = 720Xh (CF = 1)
\ JZ         = 740Xh (ZF = 1)
\ JNO        = 710Xh (OF = 0)

\ ----- Mapowanie rejestrów i operacji -----
\ Rejestry:
\ 000 = AX, 001 = CX, 010 = DX, 011 = BX
\ 100 = SP, 101 = BP, 110 = SI, 111 = DI
\
\ Operacje:
\ INC = 8, DEC = 9, PUSH = A, POP = B, XCHG = C

\ ----- Zawartość pamięci RAM -----
\ LAB 3
\dw 34560h:
\	9000h,   \ XCHG AX/BX
\    6E00h,   \ NOP
\    4900h,   \ DEC CX
\    74FDh,   \ JZ - X
\    5A00h   \ POP DX
\dw 34560h:
\	6E00h,   \ NOP
\   5A00h,   \ POP DX
\    4900h,   \ DEC CX
\    74FDh   \ J
dw 34560h:
6E00h, \ NOP
9000h, \ XCHG AX,BX
3408h, \ XOR 8h
2500h, \ AND 00F0h
00F0h,
74FBh  \ JZ

\ XOR AL(0XXX) ACC, Data8     34XX     W=0
\ AND AX(0XXX) ACC, Data16    25XX     W=1

    

\ ----- Obszar stosu -----
dw 44570h:12, 23, 34, 45 \ początkowe dane na stosie

\ ----- Makra -----
macro fl         : {load rm,flags;}
macro dec reg    : {sub reg,reg,z,z;fl;}
macro inc reg    : {add reg,reg,1,z;fl;}
macro mov reg1,reg2 : {or reg1,reg2,z;}

\ =========================================
\             PROGRAM GŁÓWNY
\ =========================================

odczyt_rozkazu
    {mov pom1,cs;}
    {mov rq,ip;}
    {cjs nz,obadrfiz;}                       \ zamiana adresu logicznego na fizyczny
    {and nil,pom1,pom1;oey;ewl;}             \ wystawienie dolnego słowa adresu
    {R;mov rr,bus_d;cjp rdm,cp;}             \ odczyt rozkazu z RAM

    \ Dekodowanie rozkazu
    {and rq,rr,FF00h;}

    \ Rozpoznawanie rozkazów
    {xor nil,rq,6E00h;fl;} {cjp RM_Z,roz_nop__dek2_wyk;}
    {xor nil,rq,4900h;fl;} {cjp RM_Z,roz_dec_cx_wyk;}
    {xor nil,rq,5A00h;fl;} {cjp RM_Z,roz_pop_dx_wyk;}
    {xor nil,rq,9000h;fl;} {cjp RM_Z,roz_xchg_ax_wyk;}
    {xor nil,rq,4000h;fl;} {cjp RM_Z,roz_inc__ax_wyk;}
    {xor nil,rq,5300h;fl;} {cjp RM_Z,roz_push_bx_wyk;}
    {xor nil,rq,7200h;fl;} {cjp RM_Z,roz_jc_wyk;}
    {xor nil,rq,7400h;fl;} {cjp RM_Z,roz_jz_wyk;}
    {xor nil,rq,7100h;fl;} {cjp RM_Z,roz_jno_wyk;}
	{xor nil,rq,3400h;fl;} {cjp RM_Z,roz_xor_al_wyk;}
	{xor nil,rq,2500h;fl;} {cjp RM_Z,roz_and_ax_wyk;}
wroc
{end;}

\ =========================================
\         PROCEDURY WYKONAWCZE
\ =========================================

roz_nop__dek2_wyk
    {jmap zapis_powrotny;}

roz_dec_cx_wyk
	{load rm, rn;}
    {dec cx;fl;cem_c;}
    {load rn, rm;}
    {jmap zapis_powrotny;}

roz_xchg_ax_wyk
    {mov pom1,bx;}                          \ zapis BX do pom1
    {mov bx,ax;}                            \ AX do BX
    {mov ax,pom1;}                          \ przywrócenie wartości do AX
    {jmap zapis_powrotny;}

roz_inc__ax_wyk
    {load rm,rn;}
    {inc ax;fl;cem_c;}                      \ inkrementacja AX, aktualizacja flag
    {load rn,rm;}
    {jmap zapis_powrotny;}

roz_push_bx_wyk
    {sub sp,sp,1,nz;fl;}                    \ dekrementacja SP
    {cjp rm_c,modyf_ss;}                    \ sprawdzenie przepełnienia segmentu
    {jmap omin;}

roz_jc_wyk
    {load rm, rn;}
    {cjp not rm_c,zapis_powrotny;}           \ skok, jeśli CF = 1 (przeniesienie)
    {jmap wykonaj_j;}

roz_jno_wyk
    {load rm, rn;} 							 \brany jest pod uwagę rejestr znaczników programisty rn
    {cjp rm_v,zapis_powrotny;}               \ brak skoku, jeśli OF = 1 (przepełnienie)
    {jmap wykonaj_j;}

roz_jz_wyk
    {load rm,rn;}
    {cjp not rm_z,zapis_powrotny;}           \ skok, jeśli ZF = 1 (zero)
	\inaczej bedzie skok
	{and rq,rr,00FFh;}\wydzielenie delta_ip
	{and nil,rq,0080h;fl;}\spr czy skok do przodu lub tylu
	{cjp rm_z,dodatnia;}\dla dodatniego delta_ip omjamy nastepna linie
	{or rq,rr,FF00h;}\dla ujemnego delta_ip
	
dodatnia
 	{add ip,ip,rq,z;}
 	{jmap odczyt_rozkazu;}

wykonaj_j
    {and rq,rr,00FFh;}                      \ wyodrębnienie delta IP
    {and nil,rq,0080h;fl;}
    {cjp rm_z,dodatnia_j;}
    {cjp not rm_z, ujemna_j;}
	
ujemna_j
	{or rq, rq, FF00h;}
	{add ip, ip, rq, z;}
	{cjp rm_z,modyf_cs_j;}
	{jmap odczyt_rozkazu;}
	
dodatnia_j
    {add ip,ip,rq,z;fl;}                    \ skok o delta IP
    {cjp rm_z,modyf_cs_j;}
    {jmap odczyt_rozkazu;}

modyf_cs_j
    {add cs,cs,1000h,z;}                    \ zmiana segmentu
    {cjs nz,obadrfiz;}
    {jmap odczyt_rozkazu;}

roz_pop_dx_wyk
    \ Przygotowanie adresu stosu
    {mov pom1,ss;}
    {mov rq,sp;}
    {cjs nz,obadrfiz;}

    \ Odczyt ze stosu
    {and nil,pom1,pom1;oey;ewl;}
    {and nil,pom2,pom2;oey;ewh;}
    {R;mov dx,bus_d;cjp rdm,cp;}

    \ Inkrementacja SP po POP
    {add sp,sp,1,z;fl;}
    {cjp rm_z,modyf_ss_pop;}
    {jmap zapis_powrotny;}

roz_xor_al_wyk
	{and pom1,rr,00FFh;}       \ Wydzielenie młodszych 8 bitów z rr – trafiają one do pom1 (czyli mamy AL)
	{xor pom2,pom2,pom2;}      \ Zerowanie rejestru pom2
	{mov pom2,ax;}             \ Kopiowanie całego rejestru ax do pom2 (czyli zawiera AH i AL)
	{and pom2,pom2,FF00h;}     \ Wydzielenie starszego bajtu (AH) z ax i zapis do pom2
	{and ax,ax,00FFh;}         \ Zostawiamy tylko AL w ax, czyli zerujemy AH
	{push nz,7;}               \ Przygotowanie przesunięcia o 8 bitów w lewo (czyli pomnożenie przez 256)
	    {sll ax;}              \ Przesunięcie ax w lewo – przemieszczenie AL na miejsce AH
	    {sll pom1;}            \ To samo dla pom1 (czyli też przeniesienie AL do AH)
	{rfct;}                    \ Koniec pętli/pakietu przesunięć (restore flags & control token)
	{load rm,z;}               \ Załadowanie adresu z do rm (rejestr pamięci)
	{xor ax,ax,pom1;fl;cem_v;cem_c;} \ XOR pomiędzy ax i pom1, wynik w ax, aktualizacja znaczników
	                               \ (ale overflow i carry będą i tak zerowe dla XOR)
	{load rn,rm;}              \ Załaduj wynik z rm do rn (do dalszego zapisu)
	{push nz,7;}               \ Przygotowanie do przesunięcia o 8 bitów w PRAWO (czyli dzielenie przez 256)
	    {srl ax;}              \ Przesunięcie w prawo – przywracamy AL na miejsce
	{rfct;}                    \ Koniec pakietu przesunięć
	{or ax,ax,pom2;}           \ Doklejenie AH z pom2 do AL – przywracamy pełne AX (AH:AL)
	{jmap zapis_powrotny;}     \ Skok do procedury zapisującej wynik do pamięci


roz_and_ax_wyk
	{add ip,ip,1,z;fl;}        \ Przesunięcie wskaźnika instrukcji o 1 (kolejny bajt), aktualizacja znaczników
	{cjp rm_z,modyf_css;}      \ Jeśli bit `rm_z` ustawiony, to skocz do procedury modyfikującej segment `cs`
	{jmap odczyt_drugiej_komorki;} \ Skok do procedury odczytującej drugą komórkę z RAM

	
odczyt_drugiej_komorki \operacja and 2 bajtowa
	{mov pom1,cs;}
	{mov rq,ip;}
	{cjs nz,obadrfiz;}
	{and nil,pom1,pom1;oey;ewl;}
	{and nil, pom2,pom2;oey;ewh;}
	{xor pom1,pom1,pom1;}\zerowanie pom1
	{R; mov pom1,bus_d; cjp rdm,cp;}\w pom1 odczytana druga komorka(2 bajtowa) z RAM
	
	\ *Data 16*
	\
	\ fragment dodany dla zamiany bajtow miejscami w data16
	\dla big endian nalezy ten fragment wlaczyc a dla little endian zostawic jako komentarz
	{xor pom2,pom2,pom2;}\zerowanie pom2
	{and pom2,pom1,00FFh;}\wydzielenie 8 mlodszych bitow
	{and pom1,pom1,FF00h;}\wydzielenie 8 starszych bitow
	{push nz,7;}		
		{sll pom2;}			\przesuwamy pom2 w lewo o 8 bitow
		{srl pom1;}			\przesuwamy pom1 w prawo o 8 bitow
	{rfct;}
	{or pom1,pom1,pom2;}\laczymy pom1 i pom2 --> w rezultacie w pom1 bajty zostaly zamienione miejscami
	\koniec fragmentu dodanego  
	
	{load rm,z;}		
	{and ax,ax,pom1;fl;cem_v;cem_c;}\w bitach overflow i carry w rej znacznikow powinny pozostac zera
	\chociaz i tak nie ma szans, ze beda ustawione operacja xor.
	{load rn,rm;}
	{jmap zapis_powrotny;}
	
modyf_css
	{add cs,cs,1000h,z;}

modyf_ss_pop
    {add ss,ss,1000h,z;}
    {jmap zapis_powrotny;}

modyf_ss
    {sub ss,ss,1000h,nz;}

omin
    {mov pom1,ss;}
    {mov rq,sp;}
    {cjs nz,obadrfiz;}
    {and nil,pom1,pom1;oey;ewl;}
    {and nil,pom2,pom2;oey;ewh;}
    {W;mov nil,bx;oey;cjp rdm,cp;}           \ zapis BX na stos
    {jmap zapis_powrotny;}

zapis_powrotny
    {add ip,ip,1,z;fl;}
    {cjp rm_z,modyf_cs;}
    {jmap odczyt_rozkazu;}

modyf_cs
    {add cs,cs,1000h,z;}
    {jmap odczyt_rozkazu;}

\ =========================================
\       PODPROGRAM: ADRES FIZYCZNY
\ =========================================

obadrfiz
    {load rm,z;}
    {and pom2,pom2,z;}
    {push nz,3;}                            \ przesunięcia do wyznaczenia adresu fizycznego
        {sll pom1,pom1;}
        {sl.25 pom2,pom2;}
    {rfct;}

    {load rm,z;}
    {add pom1,pom1,rq,z;fl;}                \ końcowe obliczenie adresu
    {add pom2,pom2,z,rm_c;}
    {load rm,z;}
    {crtn nz;}
