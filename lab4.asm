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
accept ip:FFFFh         \ ustawienie IP
accept cx:5678h         \ ustawienie CX
accept ax:7000h         \ ustawienie AX
accept bx:7001h         \ ustawienie BX
accept cx:7002h         \ ponowne ustawienie CX (korekta)
accept dx:7003h         \ ustawienie DX
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
dw 4455Fh:
    6E00h,   \ NOP
    72FEh,   \ JC - 2
    4900h,   \ DEC CX
    74FEh,   \ JZ + 2
    5A00h,   \ POP DX
    7101h,   \ JNO + 2
    9000h,   \ XCHG AX/BX
    4000h,   \ INC AX
    5300h    \ PUSH BX

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
    {cjs nz,obadrfiz;}                      \ zamiana adresu logicznego na fizyczny
    {and nil,pom1,pom1;oey;ewl;}             \ wystawienie dolnego słowa adresu
    {and nil,pom2,pom2;oey;ewh;}             \ wystawienie górnego słowa adresu
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

wroc
{end;}

\ =========================================
\         PROCEDURY WYKONAWCZE
\ =========================================

roz_nop__dek2_wyk
    {jmap zapis_powrotny;}

roz_dec_cx_wyk
    {dec cx;}
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
    {load rm,flags;}
    {cjp not rm_c,zapis_powrotny;}           \ skok, jeśli CF = 1 (przeniesienie)
    {jmap wykonaj_j;}

roz_jz_wyk
    {load rm,flags;}
    {cjp not rm_z,zapis_powrotny;}           \ skok, jeśli ZF = 1 (zero)
    {jmap wykonaj_j;}

roz_jno_wyk
    {load rm,flags;}
    {cjp rm_v,zapis_powrotny;}               \ brak skoku, jeśli OF = 1 (przepełnienie)
    {jmap wykonaj_j;}

wykonaj_j
    {and rq,rr,00FFh;}                      \ wyodrębnienie delta IP
    {and nil,rq,0080h;fl;}
    {cjp rm_z,dodatnia_j;}
	{or rq, rq, ff00h;}
	{add ip, ip, rq, z; fl;}
	{cjp rm_z, modyf_cs_j;}
	{jmap zapis_powrotny;}
	
dodatnia_j
    {add ip,ip,rq,z;fl;}                    \ skok o delta IP
    {cjp rm_z,modyf_cs_j;}
    {jmap zapis_powrotny;}

modyf_cs_j
    {add cs,cs,1000h,z;}                    \ zmiana segmentu
    {jmap zapis_powrotny;}

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
