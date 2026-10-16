/**
 * Adapter de entrada HTTP: controllers REST, DTOs de request/response, validação de entrada e
 * tradução de erros para respostas HTTP.
 *
 * <p>Os DTOs ficam aqui e nunca são entidades do domínio nem entidades JPA: o contrato público da
 * API evolui separado do modelo interno.
 */
package dev.payments.orchestrator.adapter.in.web;
