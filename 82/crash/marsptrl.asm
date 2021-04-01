;=================================
; Mars Patrol 2.0
; by Zombi
; E-MAIL: zombis_inbox@hotmail.com
; URL: zombi.web.com
; Release date: 22/01/2000
; Calculator(s): 82
; Shell: Ion
;---------------------------------
; You may edit this code for
; personal use only.
; Under NO circumstances may you
; distribute the changed source or
; a compiled version.
; Ports are the ONLY exception,
; but you still NEED to notify
; Zombi and get approval.
;---------------------------------
; View the text file included for
; more information about the game
; and credits
;=================================

#include "crash82.inc"


#define	NO_MOD_X
#define	landarray	0
#define	rockarray	landarray+48
#define	minearray	rockarray+3
#define	bulletarray	minearray+4
#define	alienarray	bulletarray+8
#define	ufoarray	alienarray+12
#define	alienbullets	ufoarray+12
#define	ufobombs	alienbullets+6
#define	scrollspeed	99	;ufobombs+6
#define	slowscroll	scrollspeed+1
#define	levelcount	slowscroll+1
#define	subcount	levelcount+1
#define	allowmove	subcount+1
#define	buggyxpos	allowmove+1
#define	buggyypos	buggyxpos+1
#define jumpcounter	buggyypos+1
#define	bulletxpos	jumpcounter+1
#define	bulletypos	bulletxpos+1
#define	bulletdist	bulletypos+1
#define	backgroundpointer	bulletdist+1
#define	alternate	backgroundpointer+1
#define	crashed		alternate+1
#define	checkpoint	crashed+1
#define	checkcounter	checkpoint+1
#define	lives		checkcounter+1
#define	score		lives+1
#define	menucount	score+2
#define	randseed	menucount+2
#define	levelmem	randseed+1
#define DefaultXSpriteHeight	8
#define	alienhoverlength	12
#define alienholdfireprob	30
#define	landlevel		54
#define	bl			32 
#define	horizontalbulletdist	10
#define	initialmenudelay	20000

      .org  START_ADDR
	.db	"Mars Patrol 2.0",0

start:
	set 7,(iy+$14)
	ld	a,(RNDSEED)
	ld	(APD_BUF+randseed),a
startprog:
	call _cleargbuf
	ld	hl,initialmenudelay
	ld	(APD_BUF+menucount),hl
	ld	bc,120
	ld	de,GRAPH_MEM	
	ld	hl,title
	ldir
	ld	hl,GRAPH_MEM+684
	ld	b,84
title_bar:
	ld	(hl),255
	inc	hl
	djnz	title_bar
	set	3,(iy+5)
	ld	bc,$3901
	ld	(CURSOR_X),bc
	ld	hl,txtVersion
	ROM_CALL(D_ZM_STR)
	ld	bc,$392A
	ld	(CURSOR_X),bc
	ld	hl,txtURL
	ROM_CALL(D_ZM_STR)
	res	3,(iy+5)
	ld	bc,$0C1E
	ld	(CURSOR_X),bc
	ld	hl,txtStart
	ROM_CALL(D_ZM_STR)
	ld	bc,$121D
	ld	(CURSOR_X),bc
	ld	hl,txtExit
	ROM_CALL(D_ZM_STR)
	ld	bc,$2A1E
	ld	(CURSOR_X),bc
	ld	hl,txtHighScore
	ROM_CALL(D_ZM_STR)
	ld	bc,$3025
	ld	(CURSOR_X),bc
	ld	hl,(highscore)
	call _setxxxxop2
	call _op2toop1
	ld	a,5
	call _dispop1a
	ld	bc,$1E1E
	ld	(CURSOR_X),bc
	ld	hl,txtCourse
	ROM_CALL(D_ZM_STR)
	ld	b,5
	ld	a,24
	ld	l,31
	ld	ix,sprLeft
	call	ionPutSprite
	ld	b,5
	ld	a,66
	ld	l,31
	ld	ix,sprRight
	call	ionPutSprite
	call	putRandseed
menuloop:
	call	resetKeyport
	ld	a,$fd
	out	(1),a
	in	a,(1)
	cp	191
	jp	z,quit
	call	resetKeyport
	ld	a,$bf
	out	(1),a
	in	a,(1)
	cp	223
	jp	z,startgame
	ld	ix,APD_BUF
	call	resetKeyport
	ld	a,$fe
	out	(1),a
	in	a,(1)
	cp	253
	jr	z,mnuLeft
	cp	251
	jr	z,mnuRight
	jr	nokeypress
mnuRight:
	inc	(ix+randseed)
	jr	leftorright
mnuLeft:
	dec	(ix+randseed)
leftorright:
	call	putRandseed
	call	CR_GRBCopy
	call	menudelay
	jr	keypressed
nokeypress:
	ld	hl,initialmenudelay
	ld	(APD_BUF+menucount),hl
keypressed:
	call	CR_GRBCopy
	jr	menuloop
startgame:
	call	getready
	ld	ix,APD_BUF
	ld	h,0
	ld	l,(ix+randseed)
	ld	(RNDSEED),hl
	ld	c,1
	ld	e,0
randlevel:
	ld	hl,APD_BUF+levelmem
	ld	d,0
	add	hl,de
	ld	a,c
	cp	9
	jr	z,randcheck
	bit	0,c
	jr	z,randland
randagain:
	call	GETRAND
	and	%00000111
	cp	5
	jr	nc,randagain
	add	a,231
	ld	(hl),a
	jr	randdone
randcheck:
	ld	c,0
	ld	(hl),236
	jr	randdone
randland:
	call	GETRAND
	and	%00011111
	add	a,6
	ld	(hl),a
randdone:
	inc	e
	inc	c
	ld	a,e
	cp	240
	jr	nz,randlevel
	ld	(hl),230
	inc	hl
	ld	(hl),255
	call	initialise
	ld	(ix+lives),2
	ld	(ix+checkpoint),0
	ld	hl,0
	ld	(APD_BUF+score),hl
gameloop:
GetKey:
	call	resetKeyport
	ld	a,$fd
	out	(1),a
	in	a,(1)
	cp	191
	jp	z,die
	ld	a,(ix+crashed)
	cp	1
	jr	nc,nomove
	call	resetKeyport
	ld	a,$fe
	out	(1),a
	in	a,(1)
	cp	253
	call	z,left
	cp	251
	call	z,right
	cp	247
	call	z,alpha
	call	resetKeyport
	ld	a,$df
	out	(1),a
	in	a,(1)
	cp	127
	call	z,alpha
	cp	191
	call	z,second
	call	resetKeyport
	ld	a,$bf
	out	(1),a
	in	a,(1)
	cp	223
	call	z,second
	cp	191
	call	z,pause
nomove:
	ld	ix,APD_BUF
	ld	a,(ix+jumpcounter)
	cp	0
	jr	z,nojump
	cp	5
	jr	c,moveup
	cp	6
	jr	z,moveup
	cp	8
	jr	z,moveup
	cp	14
	jr	z,movedown
	cp	16
	jr	z,movedown
	cp	18
	jr	nc,movedown
	jr	nojump
moveup:
	dec	(ix+buggyypos)
	jr	nojump
movedown:
	inc	(ix+buggyypos)
	jr	nojump
nojump:
	ld	a,(ix+jumpcounter)
	cp	0
	jr	z,nojump2
	ld	(ix+allowmove),0
	inc	(ix+jumpcounter)
	ld	a,(ix+jumpcounter)
	cp	23
	jr	nz,nojump2
	ld	(ix+jumpcounter),0
nojump2:
	ld	ix,APD_BUF
	ld	a,(ix+bulletxpos)
	cp	0
	jr	z,moveverticalbullets
	add	a,3
	ld	(ix+bulletxpos),a
	dec	(ix+bulletdist)
	jr	nz,moveverticalbullets
	ld	(ix+bulletdist),horizontalbulletdist
	ld	(ix+bulletxpos),0
moveverticalbullets:
	ld	b,4
	ld	hl,APD_BUF+bulletarray
bulletloop:
	ld	a,(hl)
	cp	0
	jr	z,movenextbullet
	inc	hl
	ld	a,(hl)
	sub	3
	ld	(hl),a
	cp	6
	call	c,endbullet
	dec	hl
movenextbullet:
	inc	hl
	inc	hl
	djnz	bulletloop
	ld	a,(ix+allowmove)
	cp	0
	jr	z,cantmove
	ld	a,(ix+scrollspeed)
	cp	0
	jr	z,moveright
	jr	nz,moveleft
moveright:
	ld	a,(ix+buggyxpos)
	cp	32
	jr	z,cantmove
	inc	(ix+buggyxpos)
	jr	cantmove
moveleft:
	ld	a,(ix+buggyxpos)
	cp	12
	jr	z,cantmove
	dec	(ix+buggyxpos)
	jr	cantmove
cantmove:
	ld	a,(ix+alternate)
	cp	0
	jr	z,makeone
	ld	(ix+alternate),0
	jr	makezero
makeone:
	ld	(ix+alternate),1
makezero:
	ld	hl,APD_BUF+bulletarray
	ld	b,4
hitalien:
	ld	d,(hl)
	inc	hl
	ld	e,(hl)
	push	bc
	push	hl
	ld	hl,APD_BUF+alienarray
	ld	b,6
hitalien_embedded:
	ld	a,(hl)
	sub	3
	cp	d
	jr	nc,hitnextalien_embedded
	add	a,4
	cp	d
	jr	c,hitnextalien_embedded
	inc	hl
	inc	hl
	ld	a,(hl)
	cp	e
	jr	nc,hitnextalien_embedded2
	add	a,2
	cp	e
	jr	c,hitnextalien_embedded2
	dec	hl
	dec	hl
	ld	(hl),-8
	push	de
	ld	e,100
	call	addetoscore
	pop	de
hitnextalien_embedded:
	inc	hl
	inc	hl
hitnextalien_embedded2:
	inc	hl
	inc	hl
	djnz	hitalien_embedded
	pop	hl
	pop	bc
	inc	hl
	djnz	hitalien
	ld	hl,APD_BUF+bulletarray
	ld	b,4
hitalienbullet:
	ld	d,(hl)
	inc	hl
	ld	e,(hl)
	push	bc
	push	hl
	ld	hl,APD_BUF+alienbullets
	ld	b,6
hitbullet_embedded:
	ld	a,(hl)
	sub	3
	cp	d
	jr	nc,hitnextbullet_embedded
	add	a,6
	cp	d
	jr	c,hitnextbullet_embedded
	inc	hl
	ld	a,(hl)
	sub	3
	cp	e
	jr	nc,hitnextbullet_embedded2
	add	a,6
	cp	e
	jr	c,hitnextbullet_embedded2
	ld	(hl),0
	dec	hl
	ld	(hl),0
	push	de
	ld	e,50
	call	addetoscore
	pop	de
hitnextbullet_embedded:
	inc	hl
hitnextbullet_embedded2:
	inc	hl
	djnz	hitbullet_embedded
	pop	hl
	pop	bc
	inc	hl
	djnz	hitalienbullet
	ld	ix,APD_BUF
	ld	hl,APD_BUF+rockarray
	ld	b,3
shootrock:
	ld	a,(ix+bulletxpos)
	cp	(hl)
	jr	c,shootnextrock
	sub	9
	cp	(hl)
	jr	nc,shootnextrock
	ld	a,(ix+bulletypos)
	cp	landlevel-6
	jr	c,shootnextrock
	ld	(hl),96
	ld	(ix+bulletxpos),0
	ld	(ix+bulletdist),horizontalbulletdist
	ld	e,100
	call	addetoscore
shootnextrock:
	inc	hl
	djnz	shootrock
	call	updatebuggyypos
	ld	a,(ix+crashed)
	cp	0
	jr	nz,crashinc 
	ld	hl,APD_BUF+rockarray
	ld	b,3
hitrock:
	ld	a,(ix+buggyxpos)
	add	a,16
	cp	(hl)
	jr	c,hitnextrock
	sub	16
	cp	(hl)
	jr	nc,hitnextrock
	ld	a,(ix+buggyypos)
	cp	landlevel-10
	jr	c,hitnextrock
	call	crash
hitnextrock:
	inc	hl
	djnz	hitrock
	ld	hl,APD_BUF+minearray
	ld	b,4
hitmine:
	ld	a,(ix+buggyxpos)
	add	a,14
	cp	(hl)
	jr	c,hitnextmine
	sub	16
	cp	(hl)
	jr	nc,hitnextmine
	ld	a,(ix+jumpcounter)
	cp	0
	jr	nz,hitnextmine
	call	crash
hitnextmine:
	inc	hl
	djnz	hitmine
	ld	hl,APD_BUF+alienbullets
	ld	b,3
hitbullet:
	ld	a,(hl)
	cp	(ix+buggyxpos)
	jr	c,hitnextbullet
	sub	13
	cp	(ix+buggyxpos)
	jr	nc,hitnextbullet
	inc	hl
	ld	a,(hl)
	cp	(ix+buggyypos)
	jr	c,hitnextbullet2
	sub	8
	cp	(ix+buggyypos)
	jr	nc,hitnextbullet2
	call	crash
	dec	hl
hitnextbullet:
	inc	hl
hitnextbullet2:
	inc	hl
	djnz	hitbullet
	ld	a,(ix+buggyypos)
	cp	landlevel-5
	call	nc,crash
	jr	notcrashed
crashinc:
	inc	(ix+crashed)
	ld	a,(ix+crashed)
	cp	50
	jp	z,loselife
notcrashed:
	call	drawland
	call	CR_GRBCopy
	ld	hl,2000 
Delay:
	dec	hl
	ld	a,h 
	or	l 
	jr	nz,Delay 
	ld	ix,APD_BUF
	ld	hl,APD_BUF+alienarray
	ld	b,6
movealien:
	ld	a,(hl)
	cp	-8
	jr	z,movenextalien
	inc	hl
	bit	0,(hl)
	jr	nz,movealienright
	dec	hl
	dec	(hl)
	dec	(hl)
	ld	d,(hl)
	inc	hl
	ld	a,(hl)
	cp	alienhoverlength
	jr	nc,nobounceright
	ld	a,d
	cp	0
	jr	nz,nobounceright
	inc	(hl)
nobounceright:
	ld	a,(hl)
	cp	1
	push	bc
	jr	c,noalienshoot
	ld	a,b
	cp	4
	jr	c,doufo
	ld	c,0
	jr	doalien
doufo:
	ld	c,6
	dec	hl
	ld	a,(hl)
	inc	hl
	cp	36 
	jr	c,noalienshoot
doalien:
	ld	b,alienholdfireprob 
	call	ionRandom
	cp	0
	call	z,putalienbullet
noalienshoot:
	pop	bc
	inc	hl
	ld	a,(hl)
	inc	hl
	cp	(hl)
	jr	c,movealiendown
	dec	a
	cp	(hl)
	jr	nc,movealienup
	call	setnewboundary
	dec	hl
	jr	movenextalien2
movealienright:
	dec	hl
	inc	(hl)
	inc	(hl)
	ld	a,(hl)
	inc	hl
	cp	64
	jr	nz,nobounceleft
	inc	(hl)
nobounceleft:
	jr	nobounceright
movealiendown:
	dec	hl
	ld	a,(ix+alternate)
	cp	0
	jr	z,movenextalien2
	inc	(hl)
	jr	movenextalien2
movealienup:
	dec	hl
	ld	a,(ix+alternate)
	cp	0
	jr	z,movenextalien2
	dec	(hl)
	jr	movenextalien2
movenextalien:
	inc	hl
	inc	hl
movenextalien2:
	inc	hl
	inc	hl
	djnz	movealien
	ld	b,6
	ld	hl,APD_BUF+alienbullets
	ld	ix,APD_BUF
alienbulletloop:
	ld	a,(hl)
	cp	0
	jr	z,movenextalienbullet
	ld	a,(ix+alternate)
	cp	0
	jr	z,dontmovealienbulletright
	inc	(hl)
dontmovealienbulletright:
	inc	hl
	inc	(hl)
	ld	a,(hl)
	cp	landlevel
	jr	c,stillinair
	call	dighole
	call	endbullet
stillinair:
	dec	hl
movenextalienbullet:
	inc	hl
	inc	hl
	djnz	alienbulletloop
	ld	a,(ix+crashed)
	cp	1
	jp	nc,ss2
	ld	a,(ix+scrollspeed)
	cp	0
	jr	z,fastscroll
	ld	a,(ix+slowscroll)
	cp	0
	jr	z,ssfast
	cp	1
	jr	z,sscheck
sscheck:
	ld	a,(ix+buggyxpos)
	cp	12
	jp	z,ss
ssfast:
	ld	(ix+slowscroll),1
fastscroll:
	ld	ix,APD_BUF
	dec	(ix+subcount)
	jr	nz,contcount
	inc	(ix+levelcount)
	ld	hl,APD_BUF+levelmem
	ld	c,(ix+levelcount)
	ld	b,0
	add	hl,bc
	ld	a,(hl)
	cp	231
	jr	c,normal
	ld	(ix+subcount),1
	cp	231
	jp	z,puthole
	cp	232
	jp	z,putrock
	cp	233
	jp	z,putalien
	cp	234
	jp	z,putufo
	cp	235
	jp	z,putmine
	cp	236
	jp	z,putcheckpoint
	cp	255
	jp	z,win
normal:
	ld	(ix+subcount),a
contcount:
	dec	(ix+backgroundpointer)
	ld	a,(ix+backgroundpointer)
	cp	-1
	jr	nz,nowrap
	ld	(ix+backgroundpointer),95
nowrap:
	push	ix
	call	scrollleft
	pop	ix
	ld	hl,APD_BUF+landarray+1
	ld	b,2
	call	ionRandom
	ld	b,a
	add	a,landlevel
	ld	c,a
	ld	a,b
	add	a,(hl)
	cp	landlevel+2
	jr	c,noadjust2
	inc	c
noadjust2:
	dec	hl
	ld	(hl),c
hole0:
	ld	hl,APD_BUF+landarray+1
	ld	a,(hl)
	cp	landlevel+3
	jr	nz,hole1
	dec	hl
	ld	(hl),landlevel+4
	jr	hole5
hole1:
	cp	landlevel+4
	jr	nz,hole2
	dec	hl
	ld	(hl),landlevel+7
	jr	hole5
hole2:
	cp	landlevel+7
	jr	nz,hole3
	dec	hl
	ld	(hl),landlevel+6
	jr	hole5
hole3:
	cp	landlevel+6
	jr	nz,hole4
	dec	hl
	ld	(hl),landlevel+5
	jr	hole5
hole4:
	cp	landlevel+5
	jr	nz,hole5
	dec	hl
	ld	(hl),landlevel+2
hole5:
	jr	ss2
ss:
	ld	(ix+slowscroll),0
ss2:
	jp	gameloop
left:
	ld	ix,APD_BUF
	ld	a,(ix+jumpcounter)
	cp	0
	jr	nz,dontmoveleft
	ld	(ix+allowmove),1
	ld	(ix+scrollspeed),1
dontmoveleft:
	ret
right:
	ld	ix,APD_BUF
	ld	a,(ix+jumpcounter)
	cp	0
	jr	nz,dontmoveright
	ld	(ix+allowmove),1
	ld	(ix+scrollspeed),0
dontmoveright:
	ret
alpha:
	ld	ix,APD_BUF
	ld	a,(ix+jumpcounter)
	cp	0
	ret	nz
	inc	(ix+jumpcounter)
	ret
second:
	ld	ix,APD_BUF
	ld	hl,APD_BUF+bulletarray
	ld	b,4
	ld	a,(ix+bulletxpos)
	cp	0
	jr	nz,trybulletloop
	ld	a,(ix+buggyxpos)
	add	a,13
	ld	(ix+bulletxpos),a
	ld	a,(ix+buggyypos)
	add	a,4
	ld	(ix+bulletypos),a
trybulletloop:
	ld	a,(hl)
	cp	0
	jr	nz,trynextbullet
	ld	a,(ix+buggyxpos)
	add	a,3
	ld	(hl),a
	inc	hl
	ld	a,(ix+buggyypos)
	ld	(hl),a
	ret
trynextbullet:
	inc	hl
	inc	hl
	djnz	trybulletloop
	ret
endbullet:
	ld	(hl),0
	dec	hl
	ld	(hl),0
	inc	hl
	ret
setnewboundary:
	push	bc
	ld	b,16
	call	ionRandom
	add	a,9
	ld	(hl),a
	pop	bc
	ret
pause:
	call _cleargbuf
pause2:
	ld	b,7
	xor	a
	ld	l,0
	ld	ix,sprPaused
	call	ionPutSprite
	call	CR_GRBCopy
	ld	hl,20000
pauseddelay:
	push	hl
	call	resetKeyport
	pop	hl
	ld	a,$bf
	out	(1),a
	in	a,(1)
	cp	223
	ret	z
	dec	hl
	ld	a,h
	or	l
	jr	nz,pauseddelay
	jr	pause2
puthole:
	ld	hl,APD_BUF+landarray
	ld	(hl),landlevel+3
	ld	e,50
	call	addetoscore
	jp	contcount 
putrock:
	ld	hl,APD_BUF+rockarray
	ld	b,3
	jp	tryrockandmine
putmine:
	ld	hl,APD_BUF+minearray
	ld	b,4
	jp	tryrockandmine
putcheckpoint:
	ld	(ix+checkcounter),94
	jp	contcount
putalien:
	ld	hl,APD_BUF+alienarray
	ld	b,3
tryalienloop:
	ld	a,(hl)
	cp	-8
	jr	nz,trynextalien
	ld	(hl),94
	inc	hl
	ld	(hl),0
	inc	hl
	ld	(hl),16
	inc	hl
	call	setnewboundary
	jp	contcount
trynextalien:
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	djnz	tryalienloop
	jp	contcount
putufo:
	ld	hl,APD_BUF+ufoarray
	ld	b,3
	jr	tryalienloop
putalienbullet:
	push	hl
	dec	hl
	ld	d,(hl)
	inc	hl
	inc	hl
	ld	e,(hl)
	ld	hl,APD_BUF+alienbullets
	ld	b,0
	add	hl,bc
	ld	b,3
tryalienbulletloop:
	ld	a,(hl)
	cp	0
	jr	nz,trynextalienbullet
	ld	a,d
	add	a,2
	ld	(hl),a
	inc	hl
	ld	a,e
	add	a,8
	ld	(hl),a
	pop	hl
	ret
trynextalienbullet:
	inc	hl
	inc	hl
	djnz	tryalienbulletloop
	pop	hl
	ret
tryrockandmine:
	ld	a,(hl)
	cp	96
	jr	nz,trynextrock
	ld	(hl),94
	jp	contcount
trynextrock:
	inc	hl
	djnz	tryrockandmine
	jp	contcount
die:
	call	gameover
	jp	startprog
win:
	call _cleargbuf
	ld	ix,APD_BUF
	ld	b,(ix+lives)
	inc	b
bonus:
	ld	hl,(APD_BUF+score)
	ld	de,2000
	add	hl,de
	ld	(APD_BUF+score),hl
	djnz	bonus
	call	CR_GRBCopy
	ld	bc,$0002
	ld	(CURSOR_ROW),bc
	ld	hl,txtWin
	ROM_CALL(D_ZT_STR)
	ld	bc,$0403
	ld	(CURSOR_ROW),bc
	ld	hl,txtWin2
	ROM_CALL(D_ZT_STR)
	call	mecallmenow
	call	longdelay
	call	highscoreresult
	jp	startprog
loselife:
	ld	a,(ix+lives)
	cp	0
	jp	z,die
	dec	(ix+lives)
	call	initialise
	ld	hl,APD_BUF+levelmem
	ld	c,-1
	ld	b,0
	ld	a,(ix+checkpoint)
	cp	0
	jr	z,notpassedone
checkcheck:
	ld	a,(hl)
	cp	236
	jr	nz,trynextcheckpoint
	inc	b
	ld	a,b
	cp	(ix+checkpoint)
	jr	z,foundcheckpoint
trynextcheckpoint:
	inc	hl
	inc	c
	jr	checkcheck
foundcheckpoint:
	inc	c
notpassedone:
	ld	(ix+levelcount),c
	call	getready
	jp	notcrashed
dighole:
	ld	a,b
	cp	4
	ret	nc
	push	hl
	push	bc
	dec	hl
	ld	b,(hl)
	srl	b
	ld	a,48
	sub	b
	ld	b,0
	ld	c,a
	ld	hl,APD_BUF+landarray
	add	hl,bc
	dec	hl
	dec	hl
	dec	hl
	ld	(hl),landlevel+3
	inc	hl
	ld	(hl),landlevel+5
	inc	hl
	ld	(hl),landlevel+5
	inc	hl
	ld	(hl),landlevel+3
	pop	bc
	pop	hl
	ret
crash:
	ld	ix,APD_BUF
	ld	(ix+crashed),1
	ret
updatebuggyypos:
	ld	a,(ix+jumpcounter)
	cp	0
	jr	z,onground
	ld	a,(ix+buggyypos)
	jr	offground
onground:
	ld	b,(ix+buggyxpos)
	srl	b
	ld	a,44
	sub	b
	ld	b,0
	ld	c,a
	ld	hl,APD_BUF+landarray
	add	hl,bc
	ld	a,(hl)
	sub	8
	ld	(ix+buggyypos),a
offground:
	ret
getready:
	call _cleargbuf
	call	CR_GRBCopy	
	ld	bc,$0303
	ld	(CURSOR_ROW),bc
	ld	hl,txtGetReady
	ROM_CALL(D_ZT_STR)
	call	longdelay
	ret
gameover:
	call _cleargbuf
	call	CR_GRBCopy
	ld	bc,$0303
	ld	(CURSOR_ROW),bc
	ld	hl,txtGameOver
	ROM_CALL(D_ZT_STR)
	call	mecallmenow
highscoreresult:
	ld	hl,(APD_BUF+score)
	ld	de,(highscore)
	call	hiscr
	jr	nz,nonewscore
	ld	(highscore),hl
	ld	bc,$0105
	ld	(CURSOR_ROW),bc
	ld	hl,txtNewHighScore
	ROM_CALL(D_ZT_STR)
nonewscore:
	call	longdelay
	ret
longdelay:
	ld	b,6
d_1:
	ld	hl,0
textdelay:
	dec	hl
	ld	a,h
	or	l
	jr	nz,textdelay
	djnz	d_1
	ret
	
initialise:
	ld	hl,APD_BUF+landarray
	ld	ix,APD_BUF
	ld	(hl),landlevel+1
	ld	b,47
initloop:
	push	bc
	ld	b,2
	call	ionRandom
	ld	b,a
	add	a,landlevel
	ld	c,a
	ld	a,b
	add	a,(hl)
	cp	landlevel+2
	jr	c,noadjust
	inc	c
noadjust:
	inc	hl
	ld	(hl),c
	pop	bc
	djnz	initloop
	ld	(ix+levelcount),-1
	ld	(ix+subcount),1
	ld	b,7
	ld	hl,APD_BUF+rockarray
initrockloop:
	ld	(hl),96
	inc	hl
	djnz	initrockloop
	ld	b,8
	ld	hl,APD_BUF+bulletarray
initbulletloop:
	ld	(hl),0
	inc	hl
	djnz	initbulletloop
	ld	b,24
	ld	hl,APD_BUF+alienarray
initalienloop:
	ld	(hl),-8
	inc	hl
	djnz	initalienloop
	ld	b,12
	ld	hl,APD_BUF+alienbullets
initalienbullets:
	ld	(hl),0
	inc	hl
	djnz	initalienbullets
	ld	(ix+bulletxpos),0
	ld	(ix+bulletypos),0
	ld	(ix+bulletdist),horizontalbulletdist
	ld	(ix+scrollspeed),0
	ld	(ix+slowscroll),0
	ld	(ix+allowmove),0
	ld	(ix+buggyxpos),20
	ld	(ix+buggyypos),landlevel-8
	ld	(ix+jumpcounter),0
	ld	(ix+backgroundpointer),0
	ld	(ix+alternate),0
	ld	(ix+crashed),0
	ld	(ix+checkcounter),96
	ret
drawland:
	call _cleargbuf
	ld	ix,APD_BUF
	ld	l,(ix+buggyypos)
	ld	a,(ix+buggyxpos)
	ld	b,8
	ld	c,2
	push	af
	ld	a,(ix+crashed)
	cp	1
	jr	c,drawbuggy
	ld	ix,sprCrash
	pop	af
	jr	drawcrash
drawbuggy:
	pop	af
	ld	ix,sprBuggy
drawcrash:
	call	ionLargeSprite
	ld	hl,APD_BUF+rockarray
	ld	b,3
	ld	ix,sprRock
	call	drawrockandmine
	ld	hl,APD_BUF+minearray
	ld	b,4
	ld	ix,sprMine
	call	drawrockandmine
	ld	hl,APD_BUF+alienarray
	ld	b,6
drawalienloop:
	ld	a,b
	push	hl
	push	bc
	ld	b,(hl)
	inc	hl
	inc	hl
	ld	c,(hl)
	cp	4
	jr	c,drawUFO
	ld	hl,sprAlien
	jr	drawAlien
drawUFO:
	ld	hl,sprUFO
drawAlien:
	call	PutSprClpXOR
	pop	bc
	pop	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	djnz	drawalienloop
	ld	ix,APD_BUF
	ld	b,8
	ld	c,(ix+checkcounter)
	ld	(CURSOR_X),bc
	ld	a,(ix+checkpoint)
	add	a,'A'
	ROM_CALL(M_CHARPUT)
	ld	ix,APD_BUF
	ld	a,(ix+bulletxpos)
	cp	0
	jr	z,drawverticalbullets
	ld	b,2
	ld	a,(ix+bulletxpos)
	ld	l,(ix+bulletypos)
	ld	ix,sprHorizbullet
	call	ionPutSprite
drawverticalbullets:
	ld	b,4
	ld	hl,APD_BUF+bulletarray
	ld	ix,sprVertibullet
	ld	d,3
	call	drawbulletsloop
drawalienbullets:
	ld	b,3
	ld	hl,APD_BUF+alienbullets
	ld	ix,sprAlienbullet
	ld	d,3
	call	drawbulletsloop
drawufobombs:
	ld	b,3
	ld	hl,APD_BUF+ufobombs
	ld	ix,sprBomb
	ld	d,1
	call	drawbulletsloop
	ld	ix,APD_BUF
	ld	b,48
	ld	hl,background
	ld	e,(ix+backgroundpointer)
	srl	e
	ld	d,0
	add	hl,de
	ex	de,hl
drawbackgroundloop:
	ld	a,(de)
	cp	0
	jr	nz,drawnowrap
	ld	de,background
	ld	a,(de)
drawnowrap:
	push	de
	ld	e,a
	ld	a,%00000001
	and	(ix+backgroundpointer)
	xor	%00000001
	ld	c,a
	ld	a,b
	sla	a
	dec	a
	sub	c
	push	bc
	call	ionGetPixel
	pop	bc
	pop	de
	or	(hl)
	ld	(hl),a
	inc	de
	djnz	drawbackgroundloop
	ld	hl,GRAPH_MEM
	ld	b,84
drawstatusbarlineloop:
	ld	(hl),255
	inc	hl
	djnz	drawstatusbarlineloop
	set	3,(iy+5)
	ld	bc,$0001
	ld	(CURSOR_X),bc
	ld	hl,(APD_BUF+score)
	call _setxxxxop2
	call _op2toop1
	ld	a,5
	call _dispop1a
	res	3,(iy+5)
	ld	ix,APD_BUF
	ld	b,(ix+lives)
	ld	e,96
	ld	a,b
	cp	0
	jr	z,nolives
drawlives:
	push	bc
	ld	b,5
	ld	a,e
	sub	9
	ld	e,a
	ld	l,1
	ld	ix,sprLife
	push	de
	call	ionPutSprite
	pop	de
	pop	bc
	djnz	drawlives
nolives:
	ld	ix,APD_BUF
	ld	hl,GRAPH_MEM+38
	ld	c,%00000001
	ld	b,(ix+checkpoint)
	sla	b
	ld	a,b
	cp	0
	jr	z,noprogress
	call	horizline
noprogress:
	ld	ix,sprBar
	ld	a,21
	ld	l,1
	ld	b,5
	ld	c,7
	call	ionLargeSprite
	ld	ix,APD_BUF
	ld	hl,APD_BUF+landarray
	ld	b,48
drawlandloop:
	ld	e,(hl)
	ld	d,b
	sla	d
	call	putline
	inc	hl
	djnz	drawlandloop
	ret
drawrockandmine:
	push	hl
	push	bc
	push	ix
	ld	b,(hl)
	ld	c,landlevel-6
	push	ix
	pop	hl
	call	PutSprClpXOR
	pop	ix
	pop	bc
	pop	hl
	inc	hl
	djnz	drawrockandmine
	ret
drawbulletsloop:
	ld	a,(hl)
	cp	0
	jr	z,drawnextbullet
	push	bc
	push	hl
	ld	b,d
	ld	a,(hl)
	inc	hl
	ld	l,(hl)
	push	ix
	push	de
	call	ionPutSprite
	pop	de
	pop	ix
	pop	hl
	pop	bc
drawnextbullet:
	inc	hl
	inc	hl
	djnz	drawbulletsloop
	ret
putline:
	dec	d
	push	hl
	push	bc
	push	de
	ld	a,d
	ld	e,63
	call	ionGetPixel
	pop	de
	push	af
	ld	a,64
	sub	e
	ld	e,a
	pop	af
	ld	b,a
	rlca
	or	b
	ld	c,a
	bit	0,(ix+alternate)
	jr	z,noinvert
	xor	b
	ld	b,a
noinvert:
	dec	e
	dec	e
putlineloop:
	ld	a,b
	or	(hl)
	ld	(hl),a
	ld	a,b
	xor	c
	ld	b,a
	push	bc
	ld	bc,-12
	add	hl,bc
	pop	bc
	dec	e
	jr	nz,putlineloop
	ld	a,c
	or	(hl)
	ld	(hl),a
	push	bc
	ld	bc,-12
	add	hl,bc
	pop	bc
	ld	a,c
	or	(hl)
	ld	(hl),a
	pop	bc
	pop	hl
	inc	d
	ret
scrollleft:
	ld	b,47
	ld	hl,APD_BUF+landarray+46
scrollleftloop:
	ld	a,(hl)
	inc	hl
	ld	(hl),a
	dec	hl
	dec	hl
	djnz	scrollleftloop
	ld	hl,APD_BUF+rockarray
	ld	b,7
scrollrockandmineloop:
	ld	a,(hl)
	cp	96
	jr	z,scrollrockandmine2
	sub	2
	cp	40
	call	z,passrockormine
	ld	(hl),a
	cp	-8
	jr	nz,scrollrockandmine2
	ld	(hl),96
scrollrockandmine2:
	inc	hl
	djnz	scrollrockandmineloop
	ld	ix,APD_BUF
	ld	a,(ix+checkcounter)
	cp	96
	jr	z,nocheckpoint
	dec	(ix+checkcounter)
	dec	(ix+checkcounter)
	cp	0
	jr	nz,nocheckpoint
	ld	(ix+checkcounter),96
	call	passcheckpoint
nocheckpoint:
	ret
passrockormine:
	push	de
	ld	e,50
	call	addetoscore
	pop	de
	ret
passcheckpoint:
	inc	(ix+checkpoint)
	push	de
	push	af
	ld	e,(ix+checkpoint)
	sla	e
	sla	e
	sla	e
	sla	e
	call	addetoscore
	pop	af
	pop	de
	ret
addetoscore:
	push	af
	push	de
	push	hl
	ld	hl,(APD_BUF+score)
	ld	d,0
	add	hl,de
	ld	(APD_BUF+score),hl
	pop	hl
	pop	de
	pop	af
	ret
horizline:
_drawLine:			; draw a horizontal line
	ld	a,c		; C = initial bit pattern
	xor	(hl)		; HL -> graph buffer byte containing start of line
	ld	(hl),a
	dec	b		; B = length of line
	ld	a,b
	cp	0
	ret	z
	srl	c
	jr	nc,_drawLine
	inc	hl
	ld	c,%10000000
	ld	a,b
	srl	a
	srl	a
	srl	a
	jr	z,_drawLine
_lineLoop:
	ld	(hl),%00000000
	inc	hl
	dec	a
	jr	nz,_lineLoop
	ld	a,b
	and	%00000111
	ret	z
	ld	b,a
	jr	_drawLine
menudelay:
	ld	hl,(APD_BUF+menucount)
	ld	a,h
	or	l
	jr	z,nomenudelay
	ld	hl,(APD_BUF+menucount)
mnuDelay:
	dec	hl
	ld	a,h
	or	l
	jr	nz,mnuDelay
	ld	hl,(APD_BUF+menucount)
	ld	b,200
_dec:
	dec	hl
	djnz	_dec
	ld	(APD_BUF+menucount),hl
nomenudelay:
	ret
putRandseed:
	ld	bc,$1E3B
	ld	(CURSOR_X),bc
	ld	hl,txtBlank
	ROM_CALL(D_ZM_STR)
	ld	ix,APD_BUF
	ld	bc,$1E36
	ld	(CURSOR_X),bc
	ld	l,(ix+randseed)
	ld	h,0
	call _setxxxxop2
	call _op2toop1
	ld	a,3
	call _dispop1a
	ret
quit:
	ld	a,(APD_BUF+randseed)
	ld	(RNDSEED),a
	ret
mecallmenow:
	ld	bc,$0200
	ld	(CURSOR_ROW),bc
	ld	hl,txtScore
	ROM_CALL(D_ZT_STR)
	ld	hl,(APD_BUF+score)
	ROM_CALL(D_HL_DECI)
	ret
resetKeyport:
        ld      a,$ff
        out     (1),a
        ret
GETRAND:                        ; SET UP (RANDSEED) WITH A WORD
	PUSH HL                 ; MAYBE HAVE A COUNTER AT THE TITLE SCREEN
	PUSH BC                 ; IF YOU'RE WAITING FOR A KEY TO BE PRESSED.
	LD HL,(RNDSEED)        ;
	LD A,H                  ; JASON TODD (ALPHASOFT)
	ADD A,A
	RL L
	RL H
	LD BC,$7415
	ADD HL,BC
	LD (RNDSEED),HL
	LD A,H
	ADD A,L
	POP BC
	POP HL
	RET
PutSprClpXOR:
   XOR  A
__XChange_1:    LD   DE, 8     ; D = 0, E = Height
                OR   C                            ; If C < 0
                JP   M, _SCX_NoBotClp             ; No bottom clip.
                LD   A, $3F                       ; Is C is offscreen?
                SUB  C
                RET  C
__XChange_2:    CP   8-1       ; If C + 7 < 64
                JR   NC, _SCX_NoVertClp           ; No vertical clip.
                INC  A
                LD   E, A
                JR   _SCX_NoVertClp               ; Height = 64 - C
_SCX_NoBotClp:
__XChange_3:    CP   -(8-1)    ; Is C is offscreen?
                RET  C
                ADD  A, E                         ; Find how many lines
                LD   C, A                         ; to actually draw
                SUB  E
                NEG
                LD   E, A
                ADD  HL, DE                       ; Move HL down
                LD   E, C                         ; by -C lines
                LD   C, D
_SCX_NoVertClp: PUSH HL                           ; IX -> Sprite
                POP  IX
                LD   A, $77                       ; OP code for
                LD   (_SCX_OPchg_1), A            ;   LD   (HL), A
                LD   (_SCX_OPchg_2), A
                XOR  A                            ; Is B > 0?
                OR   B
                JP   M, _SCX_NoRightClp
                CP   89                           ; Is B < 89?
                JR   C, _SCX_ClpDone
                CP   96
                RET  NC
                LD   HL, _SCX_OPchg_1             ; Modify LD to NOP
                JR   _SCX_ClpModify
_SCX_NoRightClp:CP   -7                           ; Is B is offscreen?
                RET  C
                LD   HL, _SCX_OPchg_2             ; Modify LD to NOP
_SCX_ClpModify: LD   (HL), D
_SCX_ClpDone:   LD   B, D
                LD   H, B
                LD   L, C
                ADD  HL, BC                       ; HL = Y * 12
                ADD  HL, BC
                ADD  HL, HL
                ADD  HL, HL
                LD   C, A                         ; HL = Y*12 + X/8
                SRA  C
                SRA  C
                SRA  C
                INC  C
                ADD  HL, BC
                LD   BC, GRAPH_MEM
                ADD  HL, BC
                LD   B, E                         ; B = number of rows
                CPL
                AND  %00000111                    ; find number of
                LD   E, A                         ; instructions to jump
                ADD  A, E
                ADD  A, E
                LD   (_SCX_OPchg_3 + 1), A        ; 3 * (7 - number)
                LD   DE, 13
_SCX_LineLoop:  LD   C, (IX)
                XOR  A
_SCX_OPchg_3:   JR   _SCX_OPchg_3                 ; modify
                RR   C
                RRA
                RR   C
                RRA
                RR   C
                RRA
                RR   C
                RRA
                RR   C
                RRA
                RR   C
                RRA
                RR   C
                RRA
                XOR  (HL)                         ; XOR with background
_SCX_OPchg_1:   LD   (HL), A                      ; Write
                DEC  HL                           ; HL -> next 8 pixels
                LD   A, C
                XOR  (HL)                         ; XOR with background
_SCX_OPchg_2:   LD   (HL), A                      ; Write
                ADD  HL, DE                       ; HL -> next row
                INC  IX                           ; Increment to next data
                DJNZ _SCX_LineLoop
                RET
hiscr:	push	hl
	xor	a
	sbc	hl,de
	pop	hl
	jr	z,nnhs
	jr	nc,nhs
nnhs:	ex	de,hl
	inc	a
	ret
nhs:	or	a
	ret

_cleargbuf:
 ld hl,GRAPH_MEM
 ld de,GRAPH_MEM+1
 ld (hl),0
 ld bc,767
 ldir
 ret

_setxxxxop2:
 ROM_CALL($35B4-$1a)
 ret

_op2toop1:
 ROM_CALL($1A0F-$1A)
 ret

_dispop1a:
 ROM_CALL($2E46)
        .dw $6CA4
        .db $04

vector0:	; Sprite routine
;---------= XOR a sprite =---------

; b=size of sprite

; l=yc

; a=xc

; ix holds pointer

ionPutSprite:	ld	e,l
	ld	h,$00
	ld	d,h
	add	hl,de
	add	hl,de
	add	hl,hl
	add	hl,hl
	ld	e,a
	and	$07
	ld	c,a
	srl	e
	srl	e
	srl	e
	add	hl,de
	ld	de,GRAPH_MEM
	add	hl,de
sl1:	ld	d,(ix)
	ld	e,$00
	ld	a,c
	or	a
	jr	z,sl3
sl2:	srl	d
	rr	e
	dec	a
	jr	nz,sl2

sl3:	ld	a,(hl)
	xor	d
	ld	(hl),a
	inc	hl
	ld	a,(hl)
	xor	e
	ld	(hl),a
	ld	de,$0B
	add	hl,de
	inc	ix
	djnz	sl1
	ret

ionLargeSprite:
largeSprite:
	di
	ex	af,af'
	ld	a,c
	push	af
	ex	af,af'
	ld	e,l
	ld	h,$00
	ld	d,h
	add	hl,de
	add	hl,de
	add	hl,hl
	add	hl,hl
	ld	e,a
	and	$07
	ld	c,a
	srl	e
	srl	e
	srl	e
	add	hl,de
	ld	de,GRAPH_MEM
	add	hl,de
lsl0:	push	hl
lsl1:	ld	d,(ix)
	ld	e,$00
	ld	a,c
	or	a
	jr	z,lsl3
lsl2:	srl	d
	rr	e
	dec	a
	jr	nz,lsl2
lsl3:	ld	a,(hl)
	xor	d
	ld	(hl),a
	inc	hl
	ld	a,(hl)
	xor	e
	ld	(hl),a
	inc	ix
	ex	af,af'
	dec	a
	push	af
	ex	af,af'
	pop	af
	jr	nz,lsl1
	pop	hl
	pop	af
	push	af
	ex	af,af'
	ld	de,$0C
	add	hl,de
	djnz	lsl0
	pop	af
	ret


ionGetPixel
vector3:	; Getbit routine
;---------= Get location of a pixel =---------
; input:	e=y coordinate
;		a=x coordinate
; output:	a holds data for pixel (e.g. %00100000)
;		hl->byte where pixel is on the GRAPH_MEM
getpix:	ld	d,$00
	ld	h,d
	ld	l,e
	add	hl,de
	add	hl,de
	add	hl,hl
	add	hl,hl
	ld	de,GRAPH_MEM
	add	hl,de
;---------= Get the bit for a pixel =---------
; input:	a - x coordinate
;		hl - start location	; includes GRAPH_MEM
; returns:	a - holds bit
;		hl - location + x coordinate/8
;		b=0
;		c=a/8
vector2:	ld	b,$00
	ld	c,a
	and	%00000111
	srl	c
	srl	c
	srl	c
	add	hl,bc
	ld	b,a
	inc	b
	ld	a,%00000001
gblp:	rrca
	djnz	gblp
	ret


;---------= Random number generator =---------
; input b=upper bound
; ouput a=answer 0<=a<b
; all registers are preserved except: af and bc
ionRandom
rand:	push	hl
	push	de
	ld	hl,(TEXT_MEM2)
	ld	a,r
	ld	d,a
	ld	e,(hl)
	add	hl,de
	add	a,l
	xor	h
	ld	(TEXT_MEM2),hl
	ld	hl,0
	ld	e,a
	ld	d,h
randl:	add	hl,de
	djnz	randl
	ld	a,h
	pop	de
	pop	hl
nomore:	ret




sprBuggy:
	.db	%00011000,%00000000
	.db	%00011000,%11111100
	.db	%00011001,%10000000
	.db	%01111111,%11111111
	.db	%11111111,%11111111
	.db	%11111111,%11111110
	.db	%01001100,%10100100
	.db	%00110011,%00011000
sprCrash:
	.db	%00011000,%00000000
	.db	%00010000,%11011100
	.db	%00011001,%10000000
	.db	%01011101,%10111101
	.db	%11110111,%11110111
	.db	%11111101,%10111110
	.db	%01001100,%10100100
	.db	%00100011,%00011000
sprRock:
	.db	%00000000
	.db	%00000000
	.db	%00111000
	.db	%01111100
	.db	%01111100
	.db	%11111110
	.db	%11111110
	.db	%11111111
sprMine:
	.db	%00000000
	.db	%00000000
	.db	%00000000
	.db	%00000000
	.db	%11110000
	.db	%01100000
	.db	%01100000
	.db	%01100000
sprHorizbullet:
	.db	%11100000
	.db	%11100000
sprVertibullet:
	.db	%11000000
	.db	%11000000
	.db	%11000000
sprAlien:
	.db	%00011000
	.db	%00111100
	.db	%01011010
	.db	%01111110
	.db	%01111110
	.db	%10100101
	.db	%10011001
	.db	%11000011
sprAlienbullet:
	.db	%11100000
	.db	%11100000
	.db	%01000000
sprUFO:
	.db	%00011000
	.db	%00100100
	.db	%01000010
	.db	%01011010
	.db	%11111111
	.db	%01111110
	.db	%00100100
	.db	%01000010
sprBomb:
	.db	%11110000
sprLife:
	.db	%01100000
	.db	%01101110
	.db	%11111111
	.db	%11111111
	.db	%01110110
sprBar:
	.db	%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111
	.db	%10000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000001
	.db	%10000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000001
	.db	%10000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000001
	.db	%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111
sprPaused:
	.db	%11111000
	.db	%11111000
	.db	%11111000
	.db	%11111000
	.db	%11111000
	.db	%11111000
	.db	%11111000
sprLeft:
	.db	%00100000
	.db	%01100000
	.db	%11100000
	.db	%01100000
	.db	%00100000
sprRight:
	.db	%00100000
	.db	%00110000
	.db	%00111000
	.db	%00110000
	.db	%00100000
title:
 .db %11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111
 .db %11000111,%11100011,%11111111,%11111111,%11111111,%11111110,%00000011,%11111111,%11111111,%11111111,%11111111,%11111001
 .db %11001011,%11010011,%11111111,%11111111,%11110000,%11111001,%00111000,%11111111,%11111100,%11111111,%11110000,%01111001
 .db %10011101,%10111001,%11100000,%11001000,%11100111,%01111111,%00111100,%11110000,%01100000,%00001000,%11000111,%00011001
 .db %10011110,%01111001,%11111100,%01100111,%11100011,%11111111,%00111100,%11111110,%00111001,%11100111,%11001111,%10011001
 .db %10011111,%01111001,%11100000,%01100111,%11111001,%11111111,%00000001,%11110000,%00111001,%11100111,%11001111,%10011001
 .db %10011111,%11111001,%11001110,%01100111,%11001100,%11111111,%00111111,%11100111,%00111001,%11100111,%11001111,%00111001
 .db %10011111,%11111001,%11100000,%01100111,%11100001,%11111110,%00111111,%11110000,%00111100,%00100111,%11110000,%01111001
 .db %10011111,%11111001,%11111110,%11111111,%11111111,%11111110,%01111111,%11111111,%01111111,%11111111,%11111111,%11111001
 .db %11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111
txtGetReady:
	.db	"GET READY",0
txtGameOver:
	.db	"GAME OVER",0
txtWin:
	.db	"CONGRATULATIONS!",0
txtWin2:
	.db	"YOU WON!",0
txtVersion:
	.db	"Version 2.0",0
txtHighScore:
	.db	"High Score:",0
txtURL:
	.db	"zombi.web.com",0
txtNewHighScore:
	.db	"New High Score!",0
txtCourse:
	.db	"Course",0
txtBlank:
	.db	"      ",0
txtStart:
	.db	"2nd - Start",0
txtExit:
	.db	"CLEAR - Exit",0
txtScore:
	.db	"Score:",0
highscore:
	.db	0,0
RNDSEED:
	.dw	0
background:
	.db	bl+6,bl+5,bl+4,bl+3,bl+2,bl+1,bl+2,bl+3,bl+4,bl+3,bl+2,bl+1,bl,bl+1,bl+2,bl+3,bl+4,bl+5,bl+6,bl+7,bl+8,bl+9,bl+8,bl+7
	.db	bl+6,bl+5,bl+4,bl+5,bl+6,bl+7,bl+6,bl+5,bl+4,bl+3,bl+2,bl+1,bl+2,bl+3,bl+4,bl+5,bl+4,bl+3,bl+4,bl+5,bl+6,bl+7,bl+8,bl+7,0
.end

