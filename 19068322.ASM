printENTER MACRO
    push ax
    push dx

    mov dl, 10
    mov ah, 02h
    int 21h
    mov dl, 13
    int 21h

    pop dx
    pop ax
ENDM

printAcercaDe macro
  PUSH ax
  PUSH dx
  MOV ah, 09h
  lea dx, AcerdaDe
  int 21h
  POP dx
  POP ax
endm printAcercaDe

pushRegisters macro 
  ;push de la mayoria de registros
  PUSH ax
  PUSH bx
  PUSH cx
  PUSH dx
  PUSH di
  PUSH si

  PUSH ds
  PUSH es 
endm pushRegisters
  
popRegisters macro 
  POP es 
  POP ds
  POP si
  POP di
  POP dx
  POP cx
  POP bx
  POP ax
endm popRegisters

printSpace macro 
  PUSH ax
  PUSH dx
  
  MOV ah, 02h
  MOV dl, ' '
  int 21h

  POP dx
  POP ax
endm printSpace

datos segment

    AcerdaDe db "Solo debe ejecutar el programa y jugar.",10,13,7
    db "Para moverse presione las flechas y para salir ESC",10,13,7,'$'
    
    var dw ?

    msgNivel db 11,"Nivel: ","    ",'$'
     
    ;Mensajes de teclado
    msgTecladoAyuda db 8,"Ayuda: H"
    msgTecladoReset db 8,"Reset: R"
    msgTecladoSigNivel db 18,"Siguiente Nivel: S"
    msgTecladoAntNivel db 17,"Anterior Nivel: A"
    msgTecladoHighScore db 13,"HighScores: N"
    msgTecladoSalir db 10,"Salir: ESC"
    msgTecladoAcerdaDe db 11,"AcercaDe: M"

    msgVideoAcercaDe db 43," ========================================= "
                     db 43,"| Acerca De:            Sokoban TEC Arqui |"
                     db 43,"| Intstituto Tecnologico de Costa Rica    |"
                     db 43,"| TxtFiller:                               |"
                     db 43,"|    +Juego en Ensamblador con video      |"
                     db 43,"|    +Desarrollado por Andrew JGC         |"
                     db 43,"|    +Uso directo del teclado             |"
                     db 43,"|    +Carga de niveles automatica         |"
                     db 43,"|    +Carpeta Niveles necesaria con el    |"
                     db 43,"|     ejecutable                          |"
                     db 43,"| Semestre I   -*ENTER PARA SEGUIR*- 2020 |"
                     db 43," ========================================= " 

    msgVideoAyuda    db 43," ========================================= "
                     db 43,"| Instrucciones:        Sokoban TEC Arqui |"
                     db 43,"| Intstituto Tecnologico de Costa Rica    |"
                     db 43,"| TxtFiller:                              |"
                     db 43,"|    +Para jugar use las flechas del te-  |"
                     db 43,"|     clado                               |"
                     db 43,"|    +Para salir presione la tecla ESC    |"
                     db 43,"|    +Resetear el nivel:R HighScores: H   |"
                     db 43,"|     Siguiente y anterior nivel: S, A    |"
                     db 43,"|                                         |"
                     db 43,"| Semestre I   -*ENTER PARA SEGUIR*- 2020 |"
                     db 43," ========================================= "

    msgVideoErrNivel db 43," ========================================= "
                     db 43,"| Error Lectura:        Sokoban TEC Arqui |"
                     db 43,"| Error con la lectura de un nivel, tiene |"
                     db 43,"| diferente numero de cajas y entregas o  |"
                     db 43,"| el nivel no existe.....                 |"
                     db 43,"|    +Presione Enter para intentar leer   |"
                     db 43,"|     el siguiente nivel                  |"
                     db 43,"|    +Error con el nivel:                 |"
                     db 43,"|                                         |"
                     db 43,"|                                         |"
                     db 43,"| Semestre I   -*ENTER PARA SEGUIR*- 2020 |"
                     db 43," ========================================= "

    msgVideoPaletaColores db 32,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15
    espacio db 20h
    ;matriz de paint
    matrizVideo dw 4000 dup(9020h) ; COLOR, ASCII en TASM es AL|AH
    numFilasCargadas db 0
    cursos db 0,0,'K'
    N db 25
    M db 80

    x db 0;direccion
    y db 0;direccion
    cursor db 0,0,1,0,'_', 250 
    teclaGuardada db 0
    salir dw 0
datos ends

pila segment stack 'stack'

    dw 2048 dup (?)

pila ends

codigo segment

  assume  cs:codigo, ds:datos, ss:pila

pressEnterContinueEco proc near
  PUSH ax
  XOR ax, ax
  MOV ah, 01h
  noPressEnter:
  int 21h
  CMP al, 13
  JNE noPressEnter
  POP ax  
  ret
pressEnterContinueEco endp

getKeyPress proc near
  ;revisa si se ha presionado una tecla, la cual se retorna en el al
  MOV AH,01H
  INT 16H
  JZ noHayTecla
  XOR AH,AH
  INT 16H
  MOV teclaGuardada, al
  stc
  JMP finalGetKeyPress
  noHayTecla:
  XOR ax, ax
  clc
  finalGetKeyPress:
  ret
getKeyPress endp

verificarColisiones proc near
  pushRegisters
  ;posicion del cursor en cursor
    MOV ch, cursor[0]
    MOV cl, cursor[1]
    ADD ch, x
    ADD cl, y

    CMP ch, N
    JAE noSePuedeMover
    CMP cl, M 
    JAE noSePuedeMover
 
      sePuedeMoverCursor:
        XOR ax, ax 
        MOV x, ah
        MOV y, al
        MOV byte ptr cursor[0], ch
        MOV byte ptr cursor[1], cl
        JMP finalVerificarColisiones
      noSePuedeMover:
        JMP finalVerificarColisiones
  finalVerificarColisiones:
  popRegisters
  ret
verificarColisiones endp

movimientoCursor proc near
  ;este procedimiento se encarga del movimiento del matrizSokoban
  ;se espera del teclado que se presione 
  pushRegisters

  cicloMovimientoSokoban:
  ;CALL retardadorPantalla
  CALL getKeyPress
  JC presionoTecla
  JMP cicloMovimientoSokoban
  presionoTecla:
  ;ah ->
  ;arriba  = 72
  ;derecha = 77
  ;abajo = 80
  ;izquierda = 75
    CMP ah, 72
    JNE noPresionoArriba
    JMP presionoArriba
    noPresionoArriba:
      CMP ah, 75
      JNE noPresionoIzquierda
      JMP presionoIzquierda
      noPresionoIzquierda:
        CMP ah, 77
        JNE noPresionoDerecha
        JMP presionoDerecha
        noPresionoDerecha:    
          CMP ah, 80
          JNE noPresionoAbajo
          JMP presionoAbajo
          noPresionoAbajo:
            JMP noPresionoTecla
    ;dependiendo de la tecla la direccion cambia
    ;Arriba es    x:-1, y: 0
    ;Izquierda es x: 0, y:-1
    ;Derecha es   x: 0, y:+1
    ;Abajo es     x:+1, y: 0
    ;De esta forma puedo hacer un procedimiento que busque colisiones
    ;pero sumando siempre.
    presionoArriba:
      MOV x, -1
      MOV y, 0
      JMP finalMovimientoSokoban
    presionoIzquierda:
      MOV x, 0
      MOV y, -1
      JMP finalMovimientoSokoban
    presionoDerecha:
      MOV x, 0
      MOV y, 1
      JMP finalMovimientoSokoban
    presionoAbajo:
      MOV x, 1
      MOV y, 0
      JMP finalMovimientoSokoban
  noPresionoTecla:
  CMP al, 27
  JE salirJuego
  MOV teclaGuardada, al
  JMP finalMovimientoSokoban
  salirJuego:
    MOV ax, 1
    MOV salir, ax

  finalMovimientoSokoban:


  popRegisters
  ret
movimientoCursor endp

limpiarPantalla proc near
  PUSH ax
  PUSH bx
  PUSH cx
  PUSH dx
  PUSH di
  PUSH si
  mov  ax,0B800h      ;En esta direccion comienza la memoria de video
  mov  es,ax          ;Lo cargamos en el segmento extra
  xor  di,di          ;Ponemos DI=0. Esto equivale a mov di,0, pero
                     ;xor di,di consume 3 ciclos de reloj y con mov 4
  mov  cx,80*25       ;El tamaño total es 2000 (80 lineas x 25 columnas)

  _clear:            ;Bucle que se encargara de recorrer los 2000
                     ;caracteres de la pantalla para limpiarla
      mov  al,20h    ;20h=" "   Rellenar la pantalla con espacios
      mov  ah,00h    ;Fondo azul, letras blancas
      mov  es:[di],ax
      inc  di
      inc  di
      loop _clear
  POP si
  POP di
  POP dx
  POP cx
  POP bx
  POP ax
  ret
limpiarPantalla endp

axezador proc near
    ; supone los indices en cl y ch (fil y col)
    ; retorna en el ax el contenido
    ; supone en [si] un ptr a la matriz.
    ; no supone los tamaños en dh y dl
    
    push bx
    push cx
    push dx
    push si

    MOV al, ch
    MOV bl, M ; tamaño de columnas
    MUL bl
    XOR ch, ch
    ADD ax, cx 
    ADD si, ax; sumar el numero de fila correspondiente
    shl ax, 1
    mov ax, word ptr[si]    

    pop SI
    pop DX
    pop CX
    pop BX
    ret
axezador endp

almacenador proc near
  ; supone los indices en cl y ch (fil y col)
  ; retorna en el ax el contenido
  ; supone en [si] un ptr a la matriz.
  ; se supone en el ax el dato a guardar
  
  push bx
  push cx
  push dx
  push si
  MOV dx, ax
  MOV al, ch
  MOV bl, M ; tamaño de columnas
  MUL bl
  XOR ch, ch
  ADD ax, cx 
  ADD si, ax; sumar el numero de fila correspondiente
  shl ax, 1
  mov word ptr[si], dx  

  pop SI
  pop DX
  pop CX
  pop BX
  ret

  ret
almacenador endp

printMatrizEnVideoGeneric proc near
  ;se recibe en el si el puntero a la matriz 
  ;en el dh y dl se recibe filas y columnas 
  ;en el CH se recibe la cantidad de filas
  ;en el CL la cantidad de columnas
  pushRegisters
  XOR bx, bx
  MOV var, si;guardar el inicio de la matriz
  ciclo_PrintMatrizEnVideoGeneric:
    MOV si, var
    XOR ax, ax;calcular el numero de fila
    or al, bl
    MUL cl ; tamaño de columnas
    ADD si, ax; sumar el numero de fila correspondiente
    MOV ah, bl
    ADD ah, dh
    
    pushRegisters
      ;al, cantidad de columnas
      ;ah, numero de fila
      ;dl, numero de columna
      MOV al, 80
      MUL ah
      XOR dh, dh
      ADD ax, dx
      shl ax, 1
      mov di, ax ;posicion en la pantalla

      mov  ax,0B800h
      mov  es,ax

      mov  cl, M
      xor ch, ch
      ;inc si

      cicloPrintFilaEnVideoGeneric:;Bucle que se encargara de pintar la string
          mov  ax, [si]        ;caracteres de la pantalla para limpiarla
          mov  es:[di], ax
          inc  si             ;Pasamos a apuntar a la siguiente letra del saludo
          inc  si
          inc  di
          inc  di

      LOOP cicloPrintFilaEnVideoGeneric
      popRegisters
    INC bl
  CMP bl, ch
  JB ciclo_PrintMatrizEnVideoGeneric


  popRegisters
  ret
printMatrizEnVideoGeneric endp

imprimirStrVideo proc near
  ;este metodo imprime un string en una parte especifica de
  ;la pantalla, se recibe la fila y columna en dh, dl
  ;se recibe en el si el puntero al string like PASCAL
  pushRegisters

  MOV al, 80
  MUL dh
  shl ax, 1
  XOR dh, dh
  shl dx, 1
  ADD ax, dx
  mov di, ax ;posicion en la pantalla

  mov  ax,0B800h
  mov  es,ax

  mov  cl, byte ptr[si]
  xor ch, ch
  inc si
  inc si
  cicloImprimirStrVideo: 
      mov  ax, [si]        
      mov  es:[di], ax
      inc  si             
      inc  si
      inc  di
      inc  di

      LOOP cicloImprimirStrVideo
  popRegisters
  ret
  ret
imprimirStrVideo endp

imprimirPaletaColorVideo proc near
  ;este metodo imprime un string en una parte especifica de
  ;la pantalla, se recibe la fila y columna en dh, dl
  ;se recibe en el si el puntero al string like PASCAL
  ;/*Modificado de imprimirStrVideo, solo para la paleta de color*/
  pushRegisters
  lea si, msgVideoPaletaColores
  MOV dh, 24
  MOV dl, 0
  MOV al, 80
  MUL dh
  shl ax, 1
  XOR dh, dh
  shl dx, 1
  ADD ax, dx
  mov di, ax ;posicion en la pantalla

  mov  ax,0B800h
  mov  es,ax

  mov  cl, byte ptr[si]
  xor ch, ch
  inc si

  cicloImprimirPaletaColorVideo:    ;Bucle que se encargara de pintar la paleta de color
      mov  al, espacio    
      MOV ah, [si]
      SHL ah, 4    
      mov  es:[di], ax
      inc  si             
      inc  di
      inc  di

      LOOP cicloImprimirPaletaColorVideo
  popRegisters
  ret
  ret
imprimirPaletaColorVideo endp

imprmirCursorVideo proc near
  pushRegisters
  lea si, cursor
  inc si
  inc si
  MOV dh, cursor[0]
  MOV dl, cursor[1]
  CALL imprimirStrVideo

  popRegisters
  ret
imprmirCursorVideo endp

imprimirMatrizVideo proc near
  pushRegisters
  CALL limpiarPantalla
  XOR dx, dx
  MOV ch, 25
  MOV cl, 80
  lea si, matrizVideo
  CALL printMatrizEnVideoGeneric
  popRegisters
  ret
imprimirMatrizVideo endp

pintar proc near
  pushRegisters
  ;Esta parte lo que hace es elegir el color de la paleta y ponerlo en el cursor
  MOV al, cursor[0] 
  CMP al, 24
  JE estaEnLaPaletaDeColorX
  JMP finalPintar
  estaEnLaPaletaDeColorX:
    MOV al, cursor[1]
    CMP al, 32
    JB estaEnLaPaletaDeColorY
    JMP finalPintar
    estaEnLaPaletaDeColorY:
      MOV si, offset msgVideoPaletaColores
      INC si
      XOR ah, ah
      MOV al, cursor[1]
      ADD si, ax
      MOV al, [si]
      SHL al, 4
      OR al, 10
      MOV byte ptr cursor[5], al

  finalPintar:

  popRegisters
  ret
pintar endp

cicloGeneral proc near
  pushRegisters
  CALL imprimirMatrizVideo
  CALL imprimirPaletaColorVideo
  CALL imprmirCursorVideo
  ciclo_CicloGeneral:
    CALL movimientoCursor
    CMP salir, 1
    JE finalCicloGeneral
    CMP teclaGuardada, ' '
    JNE noPresionoEspacio
    CALL pintar
    noPresionoEspacio:

    ;CALL capturadorOpcionesMenu
    
    CALL verificarColisiones
    CALL imprimirMatrizVideo
    CALL imprimirPaletaColorVideo
    CALL imprmirCursorVideo
    JMP ciclo_CicloGeneral
  finalCicloGeneral:

  popRegisters
  ret
cicloGeneral endp

  inicio: 
    
  mov ax, datos
  mov ds, ax
  mov ax, pila
  mov ss, ax

  CALL cicloGeneral

  mov  ax,4C00h
  int  21h

codigo ends

end inicio
