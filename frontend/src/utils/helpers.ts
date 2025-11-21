import { DEGREE_TYPE_LABELS, HONORS_LABELS } from '../types';
import type { DegreeType, Honors } from '../types';

export const formatAddress = (address: string): string => {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
};

export const formatGPA = (gpa: number): string => {
  return (gpa / 100).toFixed(2);
};

export const formatDate = (timestamp: bigint): string => {
  const date = new Date(Number(timestamp) * 1000);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
};

export const getDegreeLabel = (degreeType: DegreeType): string => {
  return DEGREE_TYPE_LABELS[degreeType] || 'Unknown';
};

export const getHonorsLabel = (honors: Honors): string => {
  return HONORS_LABELS[honors] || 'None';
};

export const copyToClipboard = async (text: string): Promise<void> => {
  try {
    await navigator.clipboard.writeText(text);
  } catch (err) {
    console.error('Failed to copy:', err);
  }
};
