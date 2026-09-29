# Validação de entradas e rastreabilidade da R01 — 29/09/2026

## Problemas verificados

Antes da correção, parâmetros nulos podiam encerrar a R01 sem alertas e sem erro. Um identificador de base inexistente também selecionava implicitamente transações sem base_id. Além disso, uma execução sem alertas não preservava diretamente regra, versão e parâmetros.

## Correções

- quantidade mínima, janela e versão agora são obrigatórias e positivas;
- identificadores normais precisam corresponder a uma base sintética cadastrada;
- LEGADO_SEM_BASE é o único modo explícito para registros antigos sem base;
- o gerador não permite usar o identificador reservado;
- toda execução registra regra, versão e parâmetros, inclusive nos estados CONCLUIDA e FALHOU;
- combinações parcialmente preenchidas desses metadados são rejeitadas;
- testes que esperam zero alertas também confirmam que a execução terminou como CONCLUIDA.

## Evidências

A suíte funcional passou no banco atual e em uma instalação limpa: estrutura, C01-C12, gerador, cenários positivos, cenários negativos, falha controlada, isolamento entre bases e validações de entrada. Os três benchmarks também passaram após a mudança, com as contagens esperadas.

## Migração

O script sql/019_RASTREABILIDADE_EXECUCAO.sql adiciona os novos campos a bancos existentes. Linhas históricas podem permanecer com os três campos nulos, pois seus parâmetros exatos não podem ser reconstruídos com segurança. Novas execuções gravam o conjunto completo.
