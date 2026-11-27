@echo off
title Grade completa ipes - NAO FECHAR
cd /d "%~dp0"
echo Rodando grade completa (roxo e depois amarelo). Pode minimizar, NAO feche esta janela.
echo.
"C:\Program Files\R\R-4.6.2\bin\Rscript.exe" R\13_GRADE_COMPLETA.R roxo 2
"C:\Program Files\R\R-4.6.2\bin\Rscript.exe" R\13_GRADE_COMPLETA.R amarelo 2
echo FIM > resultados\GRADE_FIM.txt
echo.
echo TERMINOU. Pode fechar.
pause
