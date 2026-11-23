**Validação do registro de falha da R01 — 29/09/2026**

**Objetivo**

Verificar que uma falha interna após a abertura da execução:

- reverte alertas e evidências parciais;
- preserva a linha de execução;
- registra estado FALHOU, instante de conclusão, SQLSTATE e mensagem.

**Procedimento**

O teste 016_TESTE_REGISTRO_FALHA_R01.sql criou cinco saídas que normalmente gerariam um alerta. Um trigger temporário BEFORE INSERT na tabela de alertas lançou uma exceção controlada. A procedure capturou a exceção dentro do bloco de processamento.

**Resultado**

- estado final: FALHOU;
- SQLSTATE: P0001;
- mensagem: falha controlada ao persistir alerta;
- alertas persistidos: zero;
- resultado do teste: passou.

**Interpretação e limite**

O teste demonstra atomicidade do bloco de alertas e rastreabilidade de uma falha interna controlada. Como a procedure converte a exceção em aviso para preservar o registro na mesma transação, um chamador deve consultar o estado final; apenas o código de saída do cliente SQL não basta. O teste não cobre queda do servidor, perda de conexão ou falha de armazenamento.