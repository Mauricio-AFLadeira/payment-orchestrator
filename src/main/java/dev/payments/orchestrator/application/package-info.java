/**
 * Casos de uso (ex.: criar pagamento, consultar status, processar webhook) e as portas que eles
 * expõem e consomem.
 *
 * <ul>
 *   <li>{@code port.in}: interfaces que os adapters de entrada chamam (o "o que a API faz").
 *   <li>{@code port.out}: interfaces que o caso de uso precisa do mundo externo (persistência,
 *       gateway de pagamento). Os adapters de saída implementam essas interfaces.
 * </ul>
 *
 * <p>Depende apenas de {@code domain}. É aqui que ficam as fronteiras de transação.
 */
package dev.payments.orchestrator.application;
