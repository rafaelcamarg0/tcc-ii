# Plano experimental da R01

**Status:** plano preliminar do experimento.

## Objeto avaliado

A R01 identifica frequência de saídas por conta no intervalo (T - W, T], com N=5 e W=10 minutos na versão de desenvolvimento. O alerta registra parâmetros, versão, transação de referência e evidências.

Os parâmetros são experimentais e não representam limite legal ou institucional.

## Perguntas de avaliação

1. A implementação produz os alertas esperados nos casos funcionais definidos?
2. O tempo de processamento cresce de forma aceitável com o aumento do volume?
3. Qual é o custo de persistir alertas e evidências?
4. Qual é o impacto do índice sobre o tempo da R01?
5. Qual é o custo adicional da auditoria durante a carga das transações?

## Variáveis independentes

- volume-base de transações;
- quantidade e proporção de cenários positivos controlados;
- presença ou ausência do índice;
- auditoria habilitada ou desabilitada durante a carga;
- repetição experimental.

## Variáveis dependentes

- tempo de geração/carga;
- tempo de execução da R01;
- quantidade de alertas;
- quantidade de evidências;
- cobertura dos cenários positivos construídos;
- alertas fora do conjunto construído;
- volume de registros de auditoria;
- tamanho ocupado no banco, se incluído no experimento final.
## Métricas

**Cobertura funcional:** referências positivas construídas que receberam alerta / referências positivas construídas.

**Alertas adicionais:** total de alertas - alertas esperados nos cenários controlados.

**Tempo:** duração entre o início e o fim da operação, em milissegundos, medida no servidor PostgreSQL.

**Vazão:** quantidade processada / tempo de execução em segundos.

**Sobrecarga da auditoria:** (tempo com auditoria - tempo sem auditoria) / tempo sem auditoria x 100.

**Ganho do índice:** (tempo sem índice - tempo com índice) / tempo sem índice x 100.

Mediana e dispersão devem acompanhar os tempos. Média isolada não será usada como único resumo.

## Controles

- mesma imagem e versão do PostgreSQL;
- mesma semente e distribuição sintética;
- mesmos parâmetros da R01;
- tabelas limpas antes de cada repetição;
- uma execução de aquecimento descartada;
- mesma quantidade de repetições por condição;
- validação automática das contagens esperadas;
- registro do hardware, sistema, Docker, imagem e commit;
- ausência de dados reais ou sigilosos.

## Procedimento proposto

1. Validar novamente testes estruturais e C01-C12.
2. Gerar base negativa controlada.
3. Confirmar ausência de alertas na base negativa.
4. Injetar cenários positivos em contas exclusivas.
5. Executar aquecimento.
6. Executar repetições medidas.
7. Conferir alertas e evidências a cada repetição.
8. Repetir para todos os volumes e condições.
9. Calcular mediana, dispersão, vazão e comparações.
10. Salvar resultado bruto, configuração e commit.
11. Interpretar sem extrapolar para detecção real de PLD/FT.

## Condições iniciais sugeridas

- volumes-base: 1 mil, 10 mil e 100 mil transações;
- dez transações de fundo por cliente;
- cenários positivos: 1% do volume-base;
- cinco saídas consecutivas por cenário;
- uma repetição de aquecimento;
- no mínimo cinco medições para desenvolvimento;
- quantidade final de repetições a confirmar.

Um volume maior só será incluído se acrescentar evidência útil e não comprometer o cronograma.

## Ameaças à validade

- cenários positivos derivados da própria regra;
- ausência de validação por especialista externo;
- distribuição sintética simplificada;
- interferência de cache e processos do notebook;
- execução em um único ambiente;
- ordem fixa das condições;
- parâmetros ainda sem justificativa empírica;
- comparação restrita a uma regra e uma arquitetura.

## Interpretação proibida

Não afirmar que cobertura funcional equivale a recall real de lavagem de dinheiro. Não tratar alertas adicionais como falsos positivos reais sem ground truth externo. Não generalizar tempos para ambientes bancários de produção.
