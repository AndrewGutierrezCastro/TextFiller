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

    msgMouseX db "Pos X:",'$'
    msgMouseY db "Pos Y:",'$'

    msgVideoAcercaDe db 43," ========================================= "
                     db 43,"| Acerca De:            Sokoban TEC Arqui |"
                     db 43,"| Intstituto Tecnologico de Costa Rica    |"
                     db 43,"| TxtFiller:                              |"
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


    msgVideoPaletaColores db 32,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15
    msgVideoMenu db 47,"|AcerdaDe: A | Ayuda: H |Modo: P & F | Clear: C"
    espacio db 219
    ;matriz de paint
    matrizVideo db 4000 dup(32) ;ASCII █ y color Azul

    N db 25
    M db 80

    x db 0;direccion
    y db 0;direccion
    cursor db 0,0,1,0,178, 1 
    modo db 0 ;0 modo paint | 1 modo filler
    teclaGuardada db 0
    salir dw 0

    mouseClick dw ?
    mouseX dw ?
    mouseY dw ?
    mousePos dw ?
datos ends

pila segment stack 'stack'

    dw 2048 dup (?)

pila ends

codigo segment

  assume  cs:codigo, ds:datos, ss:pila

pressEnterContinueEco proc near
  PUSH ax
  XOR ax, ax
  MOV ah, 07h
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
  

  finalMovimientoSokoban:


  popRegisters
  ret
movimientoCursor endp

capturadorOpcionesMenu proc near
  pushRegisters
  CMP teclaGuardada, 0
  JNE hayTeclaGuardada
  JMP noPresionoTeclaAyudas
  hayTeclaGuardada:
  MOV al, teclaGuardada
  ;al ->
  ;ayuda  = H
  ;acercaDe = M
    OR al, 32; hacer mayuscula
    CMP al, 'h'
    JNE noPresionoAyuda
    JMP presionoAyuda
    noPresionoAyuda:
      CMP al, 'a'
      JNE noPresionoAcercaDe
      JMP presionoAcercaDe
      noPresionoAcercaDe:
        CMP al, 59
        JNE noPresionoEsc
        JMP presionoEscape
          noPresionoEsc:
          JMP finalCapturadorOpcionesMenu   
    presionoAyuda:
      ;se recibe en el si el puntero a la matriz 
      ;en el dh y dl se recibe filas y columnas 
      ;en el CH se recibe la cantidad de filas
      ;en el CL la cantidad de columnas
      MOV dx, 0403h
      MOV ch, 12
      MOV cl, 44
      lea si, msgVideoAyuda
      call printMatrizEnVideoGenericBytes
      call pressEnterContinueEco
      XOR al, al
      MOV teclaGuardada, al
      JMP finalCapturadorOpcionesMenu
    presionoAcercaDe:
      MOV dx, 0403h
      MOV ch, 12
      MOV cl, 44
      lea si, msgVideoAcercaDe
      call printMatrizEnVideoGenericBytes
      call pressEnterContinueEco
      XOR al, al
      MOV teclaGuardada, al
      JMP finalCapturadorOpcionesMenu
    presionoEscape:
        MOV ax, 1
        MOV salir, ax
        JMP finalCapturadorOpcionesMenu
  noPresionoTeclaAyudas:
  
  finalCapturadorOpcionesMenu:

  popRegisters
  ret
capturadorOpcionesMenu endp

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

cleanPantalla proc near
  pushRegisters
  XOR bx, bx

  cicloCleanPantalla:
    MOV byte ptr matrizVideo[bx], 32
    INC bx 
  CMP bx, 4000
  JB cicloCleanPantalla

  popRegisters
  ret
cleanPantalla endp

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
  push ax
  push bx
  push cx
  push dx
  push si
  MOV dx, ax
  MOV al, ch
  MOV bl, M ; tamaño de columnas
  MUL bl
  XOR ch, ch
  ;shl cx, 1
  ADD ax, cx 
  shl ax, 1
  ADD si, ax; sumar el numero de fila correspondiente

  mov word ptr[si], dx  

  pop SI
  pop DX
  pop CX
  pop BX
  pop AX
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
    shl ax, 1
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
      shl dx, 1
      ADD ax, dx
      shl ax, 1
      mov di, ax ;posicion en la pantalla

      mov  ax,0B800h
      mov  es,ax

      mov  cl, M
      xor ch, ch
      ;inc si

      cicloPrintFilaEnVideoGeneric:;Bucle que se encargara de pintar la string
          mov  ax, word ptr [si]        ;caracteres de la pantalla para limpiarla
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

printMatrizEnVideoGenericBytes proc near
  ;se recibe en el si el puntero a la matriz 
  ;en el dh y dl se recibe filas y columnas 
  ;en el CH se recibe la cantidad de filas
  ;en el CL la cantidad de columnas
  pushRegisters
  XOR bx, bx
  MOV var, si;guardar el inicio de la matriz
  ciclo_PrintMatrizEnVideoGenericBytes:
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

      mov  cl, byte ptr[si]
      xor ch, ch
      inc si

      cicloPrintFilaEnVideoGenericBytes:;Bucle que se encargara de pintar la string
          mov  al, [si]        ;caracteres de la pantalla para limpiarla
          mov  ah, 14          
          OR ah, 10h
          mov  es:[di], ax
          inc  si             ;Pasamos a apuntar a la siguiente letra del saludo
          inc  di
          inc  di

      LOOP cicloPrintFilaEnVideoGenericBytes
      popRegisters
    INC bl
  CMP bl, ch
  JB ciclo_PrintMatrizEnVideoGenericBytes


  popRegisters
  ret
printMatrizEnVideoGenericBytes endp

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
imprimirStrVideo endp

imprimirStrVideoBytes proc near
  ;este metodo imprime un string en una parte especifica de
  ;la pantalla, se recibe la fila y columna en dh, dl
  ;se recibe en el si el puntero al string like PASCAL
  ;Trabaja con un arreglo de bytes, solo los caracteres
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
  cicloImprimirStrVideoBytes: 
      mov  ax, [si]       
      mov ah, 15 ; letra blanca fondo negro 
      mov  es:[di], ax
      inc  si             
      inc  di
      inc  di
      LOOP cicloImprimirStrVideoBytes
  popRegisters
  ret

  ret
imprimirStrVideoBytes endp

imprimirMenuVideo proc near
  ;este metodo imprime un string en una parte especifica de
  ;la pantalla, se recibe la fila y columna en dh, dl
  ;se recibe en el si el puntero al string like PASCAL
  ;/*Modificado de imprimirStrVideo, solo para la paleta de color*/
  pushRegisters
  lea si, msgVideoPaletaColores
  MOV dh, 24
  MOV dl, 48
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

  cicloimprimirPaletaColorVideo:    ;Bucle que se encargara de pintar la paleta de color
      mov  al, espacio    
      MOV ah, [si]    
      mov  es:[di], ax
      inc  si             
      inc  di
      inc  di

      LOOP cicloimprimirPaletaColorVideo

  lea si, msgVideoMenu
  MOV dh, 24
  XOR dl, dl
  CALL imprimirStrVideoBytes
  popRegisters
  ret
  ret
imprimirMenuVideo endp

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
  ;CALL limpiarPantalla
  XOR dx, dx
  MOV ch, 25
  MOV cl, 80
  lea si, matrizVideo
  CALL printMatrizEnVideoGeneric
  popRegisters
  ret
imprimirMatrizVideo endp

elegirColorModo proc near
  pushRegisters
  ;Esta parte lo que hace es elegir el color de la paleta y ponerlo en el cursor
  MOV al, cursor[0] 
  CMP al, 24
  JE estaEnLaPaletaDeColorX
  JMP finalElegirColorModo
  estaEnLaPaletaDeColorX:
    MOV al, cursor[1]
    CMP al, 47
    JAE estaEnLaPaletaDeColorY
    JMP puedeEstarEnMenu
    estaEnLaPaletaDeColorY:
      MOV si, offset msgVideoPaletaColores
      INC si
      XOR ah, ah
      MOV al, cursor[1]
      SUB al, 48
      ADD si, ax
      MOV al, [si]
      MOV byte ptr cursor[5], al
      JMP finalElegirColorModo
    puedeEstarEnMenu:
      MOV si, offset msgVideoMenu
      INC si
      XOR ah, ah
      MOV al, cursor[1]
      ADD si, ax
      CMP byte ptr[si], 'P'
      JNE noEsModoPaint
      JMP ponerModoPaint
      noEsModoPaint:
        CMP byte ptr[si], 'F'
        JNE noEsModoFiller
        JMP ponerModoFiller
        noEsModoFiller:
          CMP byte ptr[si], 'C'
          JNE noEsCleanPantalla
          JMP opcionCleanPantalla
          noEsCleanPantalla:
            JMP finalElegirColorModo
    ponerModoPaint:
      XOR ah, ah
      MOV modo, ah
    JMP finalElegirColorModo
    ponerModoFiller:
      XOR ah, ah
      OR ah, 1
      MOV modo, ah   
    JMP finalElegirColorModo
    opcionCleanPantalla:
      
      CALL cleanPantalla  
    JMP finalElegirColorModo
  finalElegirColorModo:

  popRegisters
  ret
elegirColorModo endp

pintar proc near
  ;en el cursor esta el x & y del cursor actual
  pushRegisters
  CMP modo, 0
  JE pintarModoPaint
  CMP modo, 1
  JE pintarModoFiller
  pintarModoPaint:
    CALL modoPaint
  JMP finalPintar
  pintarModoFiller:
  JMP finalPintar

  finalPintar:
  popRegisters
  ret
pintar endp

modoPaint proc near
  ;Este procedimiento pinta en modo paint
  ; o sea de uno a uno
  pushRegisters
  MOV ch, cursor[0];poner el x & y de la matriz
  MOV cl, cursor[1];para pinter en la matriz de color
  MOV ah, cursor[5];mover el color actual del cursor
  MOV al, 219  ;Poner un espacio en blanco en el caracter
  lea si, matrizVideo
  CALL almacenador

  popRegisters
  ret
modoPaint endp

modoFiller proc near
  ;Este procedimiento pinta en modo filler
  ;o sea como el balde

  ret
modoFiller endp

cicloGeneral proc near
  pushRegisters
  CALL imprimirMatrizVideo
  CALL imprimirMenuVideo
  CALL imprmirCursorVideo


  ciclo_CicloGeneral:
    ;CALL movimientoCursor
    CALL mouseEvent
    CMP salir, 1
    JE finalCicloGeneral
    CMP mouseClick, 1
    JNE noPresionoClick
    CALL elegirColorModo
    CALL pintar
    noPresionoClick:

    CALL capturadorOpcionesMenu
    
    CALL verificarColisiones
     CALL imprimirMatrizVideo
     CALL imprimirMenuVideo
     CALL imprmirCursorVideo
    JMP ciclo_CicloGeneral
  finalCicloGeneral:

  popRegisters
  ret
cicloGeneral endp

mouseEvent proc near
  pushRegisters
    esperarMouse:
    mov ax, 1h
    int 33h
    mov  ax, 3h
    int  33h
    CMP bx, 1
    JE seMovioMouse
    MOV ax, cx
    MOV bl, 8
    DIV bl
    XOR ah, ah
    CMP al, cursor[1]
    JNE seMovioMouse

    MOV ax, dx
    MOV bl, 8
    DIV bl
    XOR ah, ah
    CMP al, cursor[0]
    JNE seMovioMouse
    mov ax, 2h
    int 33h

    ;Revisar el teclado por salir y ayuda y acerca de
    CALL getKeyPress
    JC presionoTeclaMouseEvent
    JMP esperarMouse
    seMovioMouse:
    mov ax, 2h
    int 33h
    mov  ax, 3h
    int  33h
    mov  [mouseClick], bx ; Write the value of BX to mouseClick
    mov  [mouseX], cx     ; Write the value of CX to mouseX
    mov  [mouseY], dx     ; Write the value of DX to mouseY
    

    MOV ax, [mouseX]
    MOV bl, 8
    DIV bl
    MOV cursor[1], al

    MOV ax, [mouseY]
    MOV bl, 8
    DIV bl
    MOV cursor[0], al
    JMP finalMouseEvent

    presionoTeclaMouseEvent:
    mov ax, 2h
    int 33h
    CALL capturadorOpcionesMenu
    JMP esperarMouse
    finalMouseEvent:

  popRegisters
  ret
mouseEvent endp

printAX proc
  ; imprime a la salida estándar un número que supone estar en el AX
  ; supone que es un número positivo y natural en 16 bits.
  ; lo imprime en decimal.  
    
    push AX
    push BX
    push CX
    push DX

    xor cx, cx
    mov bx, 10
  ciclo1PAX: xor dx, dx
      div bx
      push dx
      inc cx
      cmp ax, 0
      jne ciclo1PAX
      mov ah, 02h
  ciclo2PAX: pop DX
      add dl, 30h
      int 21h
      loop ciclo2PAX

    pop DX
    pop CX
    pop BX
    pop AX
    ret
printAX endP

  inicio: 
    
  mov ax, datos
  mov ds, ax
  mov ax, pila
  mov ss, ax

  CALL cicloGeneral
  ;CALL mouseEvent

  mov  ax,4C00h
  int  21h

codigo ends

end inicio
