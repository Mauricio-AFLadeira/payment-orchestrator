/**
 * Núcleo do negócio: entidades, value objects e regras de pagamento (ex.: {@code Payment},
 * {@code Money}, a máquina de estados do pagamento).
 *
 * <p>Regra de dependência: este pacote não conhece Spring, JPA, HTTP nem a Juspay. Ele não
 * importa nada de {@code application}, {@code adapter} ou {@code config}.
 */
package dev.payments.orchestrator.domain;
