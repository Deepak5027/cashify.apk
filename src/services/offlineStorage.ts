interface PendingTransaction {
  id: string;
  data: any;
  timestamp: number;
  synced: boolean;
}

class OfflineStorageService {
  private dbName = 'financeai-offline';
  private storeName = 'pending-transactions';
  private db: IDBDatabase | null = null;

  async init(): Promise<void> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, 1);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve();
      };

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;
        if (!db.objectStoreNames.contains(this.storeName)) {
          db.createObjectStore(this.storeName, { keyPath: 'id' });
        }
      };
    });
  }

  async addPendingTransaction(data: any): Promise<string> {
    await this.ensureDB();

    const transaction: PendingTransaction = {
      id: `pending-${Date.now()}-${Math.random()}`,
      data,
      timestamp: Date.now(),
      synced: false
    };

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction([this.storeName], 'readwrite');
      const store = tx.objectStore(this.storeName);
      const request = store.add(transaction);

      request.onsuccess = () => resolve(transaction.id);
      request.onerror = () => reject(request.error);
    });
  }

  async getPendingTransactions(): Promise<PendingTransaction[]> {
    await this.ensureDB();

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction([this.storeName], 'readonly');
      const store = tx.objectStore(this.storeName);
      const request = store.getAll();

      request.onsuccess = () => {
        const all = request.result as PendingTransaction[];
        resolve(all.filter(t => !t.synced));
      };
      request.onerror = () => reject(request.error);
    });
  }

  async markAsSynced(id: string): Promise<void> {
    await this.ensureDB();

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction([this.storeName], 'readwrite');
      const store = tx.objectStore(this.storeName);
      const request = store.delete(id);

      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  async getPendingCount(): Promise<number> {
    const pending = await this.getPendingTransactions();
    return pending.length;
  }

  async syncAll(): Promise<{ success: number; failed: number }> {
    const pending = await this.getPendingTransactions();
    let success = 0;
    let failed = 0;

    for (const transaction of pending) {
      try {
        const response = await fetch(transaction.data.url, {
          method: transaction.data.method || 'POST',
          headers: transaction.data.headers || {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(transaction.data.body)
        });

        if (response.ok) {
          await this.markAsSynced(transaction.id);
          success++;
        } else {
          failed++;
        }
      } catch (error) {
        console.error('Sync failed for transaction:', transaction.id, error);
        failed++;
      }
    }

    return { success, failed };
  }

  private async ensureDB(): Promise<void> {
    if (!this.db) {
      await this.init();
    }
  }
}

export const offlineStorage = new OfflineStorageService();

// Auto-sync when coming back online
window.addEventListener('online', async () => {
  console.log('Back online, syncing pending transactions...');
  try {
    const result = await offlineStorage.syncAll();
    console.log(`Sync complete: ${result.success} succeeded, ${result.failed} failed`);

    if (result.success > 0) {
      // Notify user
      const event = new CustomEvent('offline-sync-complete', {
        detail: result
      });
      window.dispatchEvent(event);
    }
  } catch (error) {
    console.error('Auto-sync failed:', error);
  }
});
