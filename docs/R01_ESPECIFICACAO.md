# R01 — frequência de saídas em janela temporal

**Status:** proposta de operacionalização em desenvolvimento.

## Definição

Para cada transação de saída de referência em T, contar as saídas da mesma conta no intervalo (T - W, T]. Emitir alerta quando a quantidade for maior ou igual a N.

Parâmetros iniciais de depuração:

- N = 5 saídas;
- W = 10 minutos;
- unidade de análise = conta;
- somente saídas;
- processamento em lote sobre base sintética estável.

Esses valores não são limites legais nem parâmetros internos de instituição financeira. Servem para verificar o funcionamento do mecanismo.

## Rastreabilidade exigida

Cada alerta deve preservar regra, versão, execução, transação de referência, contagem observada, parâmetros utilizados e todas as transações que justificaram o disparo.

Reexecutar a mesma versão sobre a mesma base não deve criar alertas duplicados.

Erros ocorridos após a abertura da execução devem reverter alertas e evidências parciais, marcar a execução como FALHOU e preservar o SQLSTATE e a mensagem. Como a exceção é convertida em aviso para que o registro sobreviva, o chamador deve verificar o estado da execução.

## Limitações desta versão

Janelas sobrepostas podem gerar alertas distintos. Transações simultâneas podem gerar vários alertas. Não há agregação entre contas de um mesmo cliente nem tratamento de dados tardios.

Essas decisões serão avaliadas antes do experimento final.
