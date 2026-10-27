ALTER PROCEDURE procMATRICULAALUNO
(
@NOME VARCHAR(50),
@CURSO CHAR(3)
)
AS
	BEGIN
			DECLARE @NovaMatricula INT
			DECLARE @PeriodoLetivo INT

	 		INSERT INTO ALUNOS (NOME)
			VALUES (@NOME)
			SET @NovaMatricula = SCOPE_IDENTITY()
			SET @PeriodoLetivo = YEAR(GETDATE())

			INSERT MATRICULA (MATRICULA, CURSO, MATERIA, PROFESSOR, PERLETIVO)
			SELECT @NovaMatricula AS Matricula, CURSO, SIGLA, PROFESSOR,@PeriodoLetivo AS Periodo
			FROM MATERIAS
			WHERE @CURSO = CURSO

			
	SELECT * FROM MATRICULA

	END

ALTER PROCEDURE sp_CadastraNotas
	(
		@MATRICULA INT,
		@CURSO CHAR(3),
		@MATERIA CHAR(3),
		@PERLETIVO CHAR(4),
		@NOTA FLOAT,
		@FALTA INT,
		@BIMESTRE INT
	)
	AS
BEGIN

		IF @BIMESTRE NOT BETWEEN 1 AND 4
		    THROW 50001, 'Bimestre inválido.', 1;

		IF @NOTA NOT BETWEEN 0 AND 10
		    THROW 50002, 'Nota inválida.', 1;

		IF @BIMESTRE = 1
		    BEGIN

                UPDATE MATRICULA
                SET N1 = @NOTA,
                    F1 = @FALTA,
                    TOTALPONTOS = @NOTA,
                    TOTALFALTAS = @FALTA,
                    MEDIA = @NOTA
                WHERE MATRICULA = @MATRICULA
                    AND CURSO = @CURSO
                    AND MATERIA = @MATERIA
                    AND PERLETIVO = @PERLETIVO;
		    END

        ELSE 
        
        IF @BIMESTRE = 2
            BEGIN

                UPDATE MATRICULA
                SET N2 = @NOTA,
                    F2 = @FALTA,
                    TOTALPONTOS = @NOTA + N1,
                    TOTALFALTAS = @FALTA + F1,
                    MEDIA = (@NOTA + N1) / 2
                WHERE MATRICULA = @MATRICULA
                    AND CURSO = @CURSO
                    AND MATERIA = @MATERIA
                    AND PERLETIVO = @PERLETIVO;
            END

        ELSE 
        
        IF @BIMESTRE = 3
            BEGIN

                UPDATE MATRICULA
                SET N3 = @NOTA,
                    F3 = @FALTA,
                    TOTALPONTOS = @NOTA + N1 + N2,
                    TOTALFALTAS = @FALTA + F1 + F2,
                    MEDIA = (@NOTA + N1 + N2) / 3
                WHERE MATRICULA = @MATRICULA
                    AND CURSO = @CURSO
                    AND MATERIA = @MATERIA
                    AND PERLETIVO = @PERLETIVO;
            END

        ELSE 
        
        IF @BIMESTRE = 4
            BEGIN

                DECLARE @RESULTADO VARCHAR(50),
                        @FREQUENCIA FLOAT,
                        @MEDIAFINAL FLOAT,
                        @CARGAHORA FLOAT,
						@FALTAS INT
                
                SET @CARGAHORA = (
                    SELECT CARGAHORARIA FROM MATERIAS 
                    WHERE       SIGLA = @MATERIA
                            AND CURSO = @CURSO)

                UPDATE MATRICULA
                SET N4 = @NOTA,
                    F4 = @FALTA,
                    TOTALPONTOS = @NOTA + N1 + N2 + N3,
                    TOTALFALTAS = @FALTA + F1 + F2 + F3,
                    MEDIA = (@NOTA + N1 + N2 + N3) / 4
                WHERE MATRICULA = @MATRICULA
                    AND CURSO = @CURSO
                    AND MATERIA = @MATERIA
                    AND PERLETIVO = @PERLETIVO;

                SELECT @MEDIAFINAL = ROUND(MEDIA, 2),
                       @FALTAS = TOTALFALTAS
                FROM MATRICULA
                WHERE MATRICULA = @MATRICULA
                AND CURSO     = @CURSO
                AND MATERIA   = @MATERIA
                AND PERLETIVO = @PERLETIVO;

                SET @FREQUENCIA = (@CARGAHORA - @FALTAS) * 100.0 / @CARGAHORA;

                IF @FREQUENCIA < 75
                    SET @RESULTADO = 'REPROVADO POR FALTA';
                ELSE IF @MEDIAFINAL >= 7
                    SET @RESULTADO = 'APROVADO';
                ELSE IF @MEDIAFINAL >= 3
                    SET @RESULTADO = 'EXAME';
                ELSE
                    SET @RESULTADO = 'REPROVADO';

                UPDATE MATRICULA
                SET PERCFREQ   = CAST(@FREQUENCIA AS DECIMAL (10,2)),
                    MEDIAFINAL = @MEDIAFINAL,
                    RESULTADO  = @RESULTADO
                WHERE MATRICULA = @MATRICULA
                AND CURSO     = @CURSO
                AND MATERIA   = @MATERIA
                AND PERLETIVO = @PERLETIVO;


            END
            

		SELECT * FROM MATRICULA	WHERE MATRICULA = @MATRICULA
END

CREATE PROCEDURE sp_LancaExame
	(
		@MATRICULA INT,
		@CURSO CHAR(3),
		@MATERIA CHAR(3),
		@PERLETIVO CHAR(4),
		@NOTAEXAME FLOAT
	)
	AS
BEGIN

		DECLARE @MEDIA FLOAT,
		        @SITUACAO VARCHAR(20),
		        @MEDIAFINAL FLOAT,
		        @RESULTADO VARCHAR(20)

		SELECT @MEDIA = MEDIA,
		       @SITUACAO = RESULTADO
		FROM MATRICULA
		WHERE MATRICULA = @MATRICULA
		AND CURSO     = @CURSO
		AND MATERIA   = @MATERIA
		AND PERLETIVO = @PERLETIVO;

		IF @SITUACAO IS NULL OR @SITUACAO <> 'EXAME'
		    THROW 50003, 'Este aluno não está em exame.', 1;

		SET @MEDIAFINAL = ROUND((@MEDIA + @NOTAEXAME) / 2, 2);

		IF @MEDIAFINAL >= 5
		    SET @RESULTADO = 'APROVADO NO EXAME';
		ELSE
		    SET @RESULTADO = 'REPROVADO NO EXAME';

		UPDATE MATRICULA
		SET NOTAEXAME  = @NOTAEXAME,
		    MEDIAFINAL = @MEDIAFINAL,
		    RESULTADO  = @RESULTADO
		WHERE MATRICULA = @MATRICULA
		AND CURSO     = @CURSO
		AND MATERIA   = @MATERIA
		AND PERLETIVO = @PERLETIVO;

		SELECT * FROM MATRICULA WHERE MATRICULA = @MATRICULA
END

DECLARE @ANO CHAR(4) = CAST(YEAR(GETDATE()) AS CHAR(4));
DECLARE @A1 INT, @A2 INT, @A3 INT;

EXEC procMATRICULAALUNO 'TESTE APROVADO', 'ENG';
EXEC procMATRICULAALUNO 'TESTE EXAME',    'ENG';
EXEC procMATRICULAALUNO 'TESTE FALTAS',   'ENG';

SELECT @A1 = MAX(MATRICULA) FROM ALUNOS WHERE NOME = 'TESTE APROVADO';
SELECT @A2 = MAX(MATRICULA) FROM ALUNOS WHERE NOME = 'TESTE EXAME';
SELECT @A3 = MAX(MATRICULA) FROM ALUNOS WHERE NOME = 'TESTE FALTAS';

EXEC sp_CadastraNotas @MATRICULA = @A1, @CURSO = 'ENG', @MATERIA = 'BDA', @PERLETIVO = @ANO, @NOTA = 7, @FALTA = 2, @BIMESTRE = 1;
EXEC sp_CadastraNotas @MATRICULA = @A1, @CURSO = 'ENG', @MATERIA = 'BDA', @PERLETIVO = @ANO, @NOTA = 8, @FALTA = 4, @BIMESTRE = 2;
EXEC sp_CadastraNotas @MATRICULA = @A1, @CURSO = 'ENG', @MATERIA = 'BDA', @PERLETIVO = @ANO, @NOTA = 6, @FALTA = 3, @BIMESTRE = 3;
EXEC sp_CadastraNotas @MATRICULA = @A1, @CURSO = 'ENG', @MATERIA = 'BDA', @PERLETIVO = @ANO, @NOTA = 9, @FALTA = 1, @BIMESTRE = 4;

EXEC sp_CadastraNotas @MATRICULA = @A2, @CURSO = 'ENG', @MATERIA = 'BDA', @PERLETIVO = @ANO, @NOTA = 5, @FALTA = 2, @BIMESTRE = 1;
EXEC sp_CadastraNotas @MATRICULA = @A2, @CURSO = 'ENG', @MATERIA = 'BDA', @PERLETIVO = @ANO, @NOTA = 4, @FALTA = 2, @BIMESTRE = 2;
EXEC sp_CadastraNotas @MATRICULA = @A2, @CURSO = 'ENG', @MATERIA = 'BDA', @PERLETIVO = @ANO, @NOTA = 6, @FALTA = 2, @BIMESTRE = 3;
EXEC sp_CadastraNotas @MATRICULA = @A2, @CURSO = 'ENG', @MATERIA = 'BDA', @PERLETIVO = @ANO, @NOTA = 5, @FALTA = 2, @BIMESTRE = 4;

EXEC sp_CadastraNotas @MATRICULA = @A3, @CURSO = 'ENG', @MATERIA = 'BDA', @PERLETIVO = @ANO, @NOTA = 8, @FALTA = 10, @BIMESTRE = 1;
EXEC sp_CadastraNotas @MATRICULA = @A3, @CURSO = 'ENG', @MATERIA = 'BDA', @PERLETIVO = @ANO, @NOTA = 8, @FALTA = 10, @BIMESTRE = 2;
EXEC sp_CadastraNotas @MATRICULA = @A3, @CURSO = 'ENG', @MATERIA = 'BDA', @PERLETIVO = @ANO, @NOTA = 8, @FALTA = 10, @BIMESTRE = 3;
EXEC sp_CadastraNotas @MATRICULA = @A3, @CURSO = 'ENG', @MATERIA = 'BDA', @PERLETIVO = @ANO, @NOTA = 8, @FALTA = 10, @BIMESTRE = 4;

SELECT * FROM MATRICULA

EXEC sp_LancaExame 9, 'ENG', 'BDA', '2026', 6;