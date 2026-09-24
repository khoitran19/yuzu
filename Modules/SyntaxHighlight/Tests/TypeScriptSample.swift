func typeScriptSample(lineCount: Int) -> [String] {
    var lines: [String] = []
    var index = 0
    while lines.count < lineCount {
        lines += """
        import { useCallback, useMemo } from 'react';
        import type { Order\(index), LineItem } from '#@/orders/types.ts';

        /**
         * Totals for order \(index).
         */
        export interface OrderTotals\(index) {
          readonly subtotal: number;
          tax?: number | null;
          items: Array<LineItem>;
        }

        const MAX_ITEMS_\(index) = 250;

        export class OrderService\(index) extends BaseService implements Disposable {
          private readonly cache = new Map<string, OrderTotals\(index)>();

          constructor(private client: HttpClient, public region = 'us-east-1') {
            super(client);
          }

          async load(id: string): Promise<Order\(index) | undefined> {
            // Reuse the cached value when present.
            const cached = this.cache.get(id);
            if (cached !== undefined && cached.items.length < MAX_ITEMS_\(index)) {
              return { ...cached, id } as Order\(index);
            }
            const response = await this.client.get(`/orders/${id}?region=${this.region}`);
            return response.json();
          }

          total(items: LineItem[]): number {
            return items.reduce((sum, item) => sum + item.price * item.quantity, 0) * 1.08;
          }
        }

        export function useOrder\(index)(id: string) {
          const service = useMemo(() => new OrderService\(index)(client), []);
          return useCallback(() => service.load(id), [service, id]);
        }

        """.components(separatedBy: "\n")
        index += 1
    }
    return Array(lines.prefix(lineCount))
}
