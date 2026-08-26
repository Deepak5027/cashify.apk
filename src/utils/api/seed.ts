import apiClient from '../../utils/apiClient';

export const seedDemoData = async () => {
  try {
    const res = await apiClient.post('/api/seed-demo-data', {});
    return res;
  } catch (error: any) {
    console.error('Seed error:', error);
    throw error;
  }
};
