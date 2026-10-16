/**
 * Business core: entities, value objects and payment rules (e.g. {@code Payment}, {@code Money},
 * the payment state machine).
 *
 * <p>Dependency rule: this package knows nothing about Spring, JPA, HTTP or Juspay. It does not
 * import anything from {@code application}, {@code adapter} or {@code config}.
 */
package dev.payments.orchestrator.domain;
