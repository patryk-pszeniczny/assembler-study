link l1:ct
link l2:rdm
link ra: 0,1,2,z
link rb: 8,9,10,z \podlaczenie 8,9 i 10 linii z magistr.danych do rejestru rb
\do [rb] mozna zapisac
\z [ra] mozna odczytac
equ ax:r0 \w programie ax i r0 to synonimy
equ cx:r1 \kolejnosc podanych par synonimów ma znaczenie, poniewaz w formacie kazdej
equ dx:r2 \instrukcji rejestr ax ma numer 0, cx--> 1, dx--> 2 etc.
equ bx:r3
equ sp:r4
equ bp:r5
equ si:r6
equ ddi:r7 \rejestr di nazwany jest ddi poniewaz di jest slowem kluczowym kompilatora Architex
equ cs:r8
equ ss:r9
equ ds:r10
equ es:r11
equ ip:r12
equ pom1:r13 \pom1 i pom2 -->rejestry pomocnicze
equ pom2:r14
equ rr:r15 \rr-->rejestr rozkazu(rej. do którego trafia postać maszynowa kolejnej odczytanej instr)
accept cs:3456h \cs:ip wskazuje na adres w RAM pierwszego rozkazu do odczytu
accept ip:FFFFh
accept cx:5678h
dw 4455Fh:6E00h,4900h,5A00h,9000h,4000h,5300h  \zawartosc pamieci RAM, 
\rozkaz NOP [DEC CX] [POP DX] [XCHG AX, BX]
\rozkaz NOP = 6E00h, [DEC CX] = 4900h, 
\rozkaz [POP DX] = 5A00h, [XCHG AX] = 9000h, [XCHG BX] = 9300h 
\rozkac [INC AX] = 4000h, [PUSH BX] = 5300h
\ REG Rejestr REG Rejestr
\ 000 = AX = 0, 100 = SP = 4  INC = 01000 = 8
\ 001 = CX = 1, 101 = BP = 5  DEC = 01001 = 9
\ 010 = DX = 2, 110 = SI = 6  PUSH = 01010 = A
\ 011 = BX = 3, 111 = DI = 7  POP = 01011  = B
\                             XCHG = 10010 = C
accept ax:7000h
accept bx:7001h
accept cx:7002h
accept dx:7003h
\wartosci poczatkowe ss i sp
accept ss:4457h
accept sp:0000h


\obszar stosu jest poczatkowo zapelniony jakas informacja
\adresy fiz 1FFFEh,1FFFFh, 20000h, 20001h
dw 44570h:12, 23, 34, 45



macro fl :{load rm, flags;} \makro fl zamienia mikroinstrukcje load rm, flags; etc
macro dec reg:{sub reg, reg,z,z;fl;}
macro inc reg:{add reg,reg,1,z;fl;}
macro mov reg1, reg2:{or reg1,reg2,z;}

odczyt_rozkazu
{mov pom1,cs;}
{mov rq,ip;}
{cjs nz,obadrfiz;} \zamiana adr logicznego na fizyczny w trybie rzeczywistym (wywol. podprogra)
{and nil,pom1,pom1;oey;ewl;}\zapis adr fizycznego do RgA tj. wystawienie adr fiz.
{and nil, pom2,pom2;oey;ewh;}\ na magistrale adresowa
{R; mov rr,bus_d; cjp rdm,cp;} \odczyt komórki RAM do rejestru rr
\\\rozkaz NOP [DEC CX] [POP DX] [XCHG AX, BX]
\rozkaz NOP [DEC CX] [POP DX] [XCHG AX, BX]
\rozkaz NOP = 6E00h, [DEC CX] = 4900h, 
\rozkaz [POP DX] = 5A00h, [XCHG AX] = 9000h, [XCHG BX] = 9300h 
\rozkac [INC AX] = 4000h, [PUSH BX] = 5300h
\\dekodowanie
\\nopik
{and rq,rr,FF00h;}


{xor nil, rq, 6E00h;fl;}
{cjp RM_Z, roz_nop__dek2_wyk;}

\\rozpoznawanie dec cx
{xor nil, rq, 4900h;fl;}
{cjp RM_Z, roz_dec_cx_wyk;}

\\rozpoznawanie POP DX
{xor nil, rq, 5A00h;fl;}
{cjp RM_Z, roz_pop_dx_wyk;}

\\rozpoznawanie xchg ax/bx
{xor nil, rq, 9000h;fl;}
{cjp RM_Z, roz_xchg_ax_wyk;}

\\rozpoznawanie inc ax
{xor nil,rq, 4000h;fl;}
{cjp RM_Z, roz_inc__ax_wyk;}

\\rozpoznawanie push bx
{xor nil,rq, 5300h;fl;}
{cjp RM_Z, roz_push_bx_wyk;}

wroc

{end;}

roz_nop__dek2_wyk
{jmap zapis_powrotny;}

roz_dec_cx_wyk
{dec cx;}
{jmap zapis_powrotny;}


roz_xchg_ax_wyk
{mov pom1, bx;} \zrzucenie wartosci z BX do pom1
{mov bx, ax;} \zrzucenie wartosci z AX do BX
{mov ax, pom1;} \zrzucenie wartosci z pom1 do BX
{jmap zapis_powrotny;}

roz_inc__ax_wyk
{load rm,rn;} \kopiuje z rn do rm
{inc ax; fl;cem_c;}\zwiekszam ax o 1, wartosc znaczników flag do rejestru rm za wyjatkiem rm_c
{load rn,rm;} \kopiowanie powrotne
{jmap zapis_powrotny;}

roz_push_bx_wyk
{sub sp,sp,1,nz;fl;}
{cjp rm_c,modyf_ss;} \ jezeli trzeba modyfikowac ss
{jmap omin;}


roz_pop_dx_wyk
\adres fizyczny
{mov pom1,ss;}
{mov rq,sp;}
{cjs nz,obadrfiz;}

\odczyt do dx ze stosu
{and nil,pom1,pom1;oey;ewl;}\zapis adr fizycznego do RgA tj. wystawienie adr fiz.
{and nil, pom2,pom2;oey;ewh;}\ na magistralę adresowa
{R; mov dx,bus_d; cjp rdm,cp;}

\Inkrementacja stosu
{add sp,sp,1,z;fl;}
{cjp rm_z,modyf_ss_pop;}
{jmap zapis_powrotny;}

modyf_ss_pop
{add ss,ss,1000h,z;}
{jmap zapis_powrotny;}



modyf_ss
{sub ss,ss,1000h,nz;}

omin
{mov pom1,ss;} \wykorzystanie podprogramu zamiany adr log na adr fiz
{mov rq,sp;}
{cjs nz,obadrfiz;}
{and nil,pom1,pom1;oey;ewl;}
{and nil, pom2,pom2;oey;ewh;}
{W; mov nil ,bx; oey; cjp rdm,cp; }\zapis do pamięci RAM(na stos)
{jmap zapis_powrotny;}

zapis_powrotny
{add ip,ip,1,z;fl;}
{cjp rm_z,modyf_cs;}
{jmap odczyt_rozkazu;}

modyf_cs
{add cs,cs,1000h,z;}
{jmap odczyt_rozkazu;}
\\ Adres logiczny podany---> pom1:rq
\\ Adres fizyczny zwracany---> pom2|pom1

obadrfiz
{load rm,z;}
{and pom2,pom2,z;}
{push nz,3;} \petla wykonywana 4 razy, mnozy segment razy 16
			 \ (4 przesuniecia w strone starszych bitów)
{sll pom1,pom1;}
{sl.25 pom2,pom2;}
{rfct;}\koniec petli

{load rm,z;}
{add pom1,pom1,rq,z;fl;} \dodaje Segment*16 do offsetu
{add pom2,pom2,z,rm_c;}
{load rm,z;}
{crtn nz;}
/*{W; mov nil ,r0; oey; cjp rdm,cp; } sposób zapisu informacji do pamięci RAM */
