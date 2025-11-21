import { useState, useEffect } from 'react';
import { useWallet } from '../contexts/WalletContext';
import { CredentialCard } from '../components/CredentialCard';
import type { Credential } from '../types';

export const StudentDashboard = () => {
  const { account, academicCredentialContract, universityRegistryContract } = useWallet();
  const [credentials, setCredentials] = useState<Array<{ id: number; data: Credential; universityName: string }>>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchCredentials = async () => {
    if (!account || !academicCredentialContract || !universityRegistryContract) return;

    setLoading(true);
    setError(null);

    try {
      const credentialIds = await academicCredentialContract.getStudentCredentials(account);

      const credentialData = await Promise.all(
        credentialIds.map(async (id: bigint) => {
          const credential = await academicCredentialContract.getCredential(id);

          let universityName = 'Unknown University';
          try {
            const university = await universityRegistryContract.getUniversity(credential.universityId);
            universityName = university.name;
          } catch (err) {
            console.error('Error fetching university:', err);
          }

          return {
            id: Number(id),
            data: credential,
            universityName
          };
        })
      );

      setCredentials(credentialData);
    } catch (err) {
      console.error('Error fetching credentials:', err);
      setError('Failed to load credentials. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (account && academicCredentialContract) {
      fetchCredentials();
    }
  }, [account, academicCredentialContract]);

  if (!account) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="bg-white p-8 rounded-lg shadow-md text-center">
          <h2 className="text-2xl font-bold text-gray-800 mb-4">Welcome to Student Dashboard</h2>
          <p className="text-gray-600 mb-6">Please connect your wallet to view your credentials</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="container mx-auto px-4">
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-800 mb-2">My Credentials</h1>
          <p className="text-gray-600">View all your academic credentials stored on the blockchain</p>
        </div>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            {error}
          </div>
        )}

        {loading ? (
          <div className="flex justify-center items-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          </div>
        ) : credentials.length === 0 ? (
          <div className="bg-white p-12 rounded-lg shadow text-center">
            <h3 className="text-xl font-semibold text-gray-700 mb-2">No Credentials Found</h3>
            <p className="text-gray-500">You don't have any academic credentials yet.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {credentials.map(({ id, data, universityName }) => (
              <CredentialCard
                key={id}
                credentialId={id}
                credential={data}
                universityName={universityName}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
