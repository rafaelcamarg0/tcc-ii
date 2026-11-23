**Validação funcional inicial — 28/09/2026**

**Ambiente observado**

- Data/hora local: 28/09/2026 20:13:38 (UTC-03:00).
- Windows: 10.0.26200.
- Docker Client/Server: 29.8.1.
- Docker Compose: 5.5.1.
- PostgreSQL: 17.11, imagem oficial Debian.
- Imagem: sha256:d74eeac9a635390a49bc21bd49fccd973de707e2a53a76ac49b552b8712ec46f.
- Commit-base: 7a7d182d3ab292bd986e2a7502648678dadec629.

**Resultado do teste estrutural**

**Resultado:** PASSOU.

Foram verificados: auditoria de INSERT, UPDATE e DELETE; snapshots antes/depois; usuário da sessão; integridade referencial; bloqueio de valor negativo; e remoção efetiva da transação.

O teste foi executado em transação com ROLLBACK, sem preservar os dados sintéticos usados.
**Resultado da R01**

**Resultado:** 12 de 12 casos passaram.

- C01: abaixo do limiar.
- C02: exatamente no limiar.
- C03: janelas sobrepostas.
- C04: limite inferior aberto.
- C05: evento imediatamente dentro da janela.
- C06: exclusão de entradas.
- C07: separação por conta.
- C08: eventos simultâneos.
- C09: independência da ordem de carga.
- C10: prevenção de alertas duplicados.
- C11: preservação de evidências e parâmetros.
- C12: trilha de auditoria.

A bateria também foi executada com ROLLBACK.

**Interpretação permitida**

Os resultados demonstram correspondência funcional entre a implementação da R01 e os casos de aceitação construídos. Eles não demonstram capacidade de identificar lavagem de dinheiro, não validam os parâmetros N=5 e W=10 minutos para uso real e não permitem calcular precisão, recall ou taxa real de falsos positivos.

**Próximo passo**

Preparar uma base sintética persistente, definir volumes e repetições, medir desempenho e discutir a representatividade dos cenários antes do experimento final.
