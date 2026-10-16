/**
 * Use cases (e.g. create payment, query status, process webhook) and the ports they expose and
 * consume.
 *
 * <ul>
 *   <li>{@code port.in}: interfaces called by inbound adapters (what the API does).
 *   <li>{@code port.out}: interfaces the use cases need from the outside world (persistence,
 *       payment gateway). Outbound adapters implement them.
 * </ul>
 *
 * <p>Depends only on {@code domain}. Transaction boundaries live here.
 */
package dev.payments.orchestrator.application;
