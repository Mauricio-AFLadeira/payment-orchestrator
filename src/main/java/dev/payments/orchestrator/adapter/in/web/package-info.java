/**
 * Inbound HTTP adapter: REST controllers, request/response DTOs, input validation and mapping of
 * errors to HTTP responses.
 *
 * <p>DTOs live here and are never domain objects or JPA entities: the public API contract evolves
 * independently from the internal model.
 */
package dev.payments.orchestrator.adapter.in.web;
