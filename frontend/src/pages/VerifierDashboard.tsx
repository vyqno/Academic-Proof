import { useState } from 'react';
import { useWallet } from '../contexts/WalletContext';
import type { VerificationResult } from '../types';
import { formatAddress, formatGPA, formatDate, getDegreeLabel, getHonorsLabel } from '../utils/helpers';

export const VerifierDashboard = () => {
  const { account, credentialVerifierContract } = useWallet();
  const [credentialId, setCredentialId] = useState('');
  const [verificationResult, setVerificationResult] = useState<VerificationResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!credentialVerifierContract) return;

    setLoading(true);
    setError(null);
    setVerificationResult(null);

    try {
      const result = await credentialVerifierContract.getCredentialDetails(credentialId);
      setVerificationResult(result);
    } catch (err) {
      console.error('Error verifying credential:', err);
      setError((err as Error).message || 'Failed to verify credential');
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (result: VerificationResult) => {
    if (!result.exists) return 'bg-gray-100 text-gray-800 border-gray-300';
    if (!result.isIssued) return 'bg-yellow-100 text-yellow-800 border-yellow-300';
    if (result.isRevoked) return 'bg-red-100 text-red-800 border-red-300';
    if (result.isValid) return 'bg-green-100 text-green-800 border-green-300';
    return 'bg-gray-100 text-gray-800 border-gray-300';
  };

  const getStatusText = (result: VerificationResult) => {
    if (!result.exists) return 'NOT FOUND';
    if (!result.isIssued) return 'PENDING APPROVAL';
    if (result.isRevoked) return 'REVOKED';
    if (result.isValid) return 'VALID';
    return 'INVALID';
  };

  if (!account) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="bg-white p-8 rounded-lg shadow-md text-center">
          <h2 className="text-2xl font-bold text-gray-800 mb-4">Verifier Dashboard</h2>
          <p className="text-gray-600 mb-6">Please connect your wallet to verify credentials</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="container mx-auto px-4 max-w-3xl">
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-800 mb-2">Verify Credential</h1>
          <p className="text-gray-600">Enter a credential ID to verify its authenticity</p>
        </div>

        <form onSubmit={handleVerify} className="bg-white p-8 rounded-lg shadow-md mb-8">
          <div className="flex gap-4">
            <input
              type="number"
              value={credentialId}
              onChange={(e) => setCredentialId(e.target.value)}
              className="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Enter Credential ID"
              required
            />
            <button
              type="submit"
              disabled={loading}
              className="bg-blue-600 text-white px-8 py-3 rounded-lg font-semibold hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Verifying...' : 'Verify'}
            </button>
          </div>
        </form>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            {error}
          </div>
        )}

        {verificationResult && (
          <div className="bg-white rounded-lg shadow-lg overflow-hidden">
            <div className={`px-6 py-4 border-b-4 ${getStatusColor(verificationResult)}`}>
              <h2 className="text-2xl font-bold">
                Status: {getStatusText(verificationResult)}
              </h2>
            </div>

            {verificationResult.exists && (
              <div className="p-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <h3 className="text-sm font-semibold text-gray-500 uppercase mb-1">
                      Credential ID
                    </h3>
                    <p className="text-lg text-gray-800">{credentialId}</p>
                  </div>

                  <div>
                    <h3 className="text-sm font-semibold text-gray-500 uppercase mb-1">
                      Student
                    </h3>
                    <p className="text-lg text-gray-800 font-mono">
                      {formatAddress(verificationResult.student)}
                    </p>
                  </div>

                  <div>
                    <h3 className="text-sm font-semibold text-gray-500 uppercase mb-1">
                      University
                    </h3>
                    <p className="text-lg text-gray-800">{verificationResult.universityName}</p>
                  </div>

                  <div>
                    <h3 className="text-sm font-semibold text-gray-500 uppercase mb-1">
                      Degree Type
                    </h3>
                    <p className="text-lg text-gray-800">
                      {getDegreeLabel(verificationResult.degreeType)}
                    </p>
                  </div>

                  <div>
                    <h3 className="text-sm font-semibold text-gray-500 uppercase mb-1">
                      Major
                    </h3>
                    <p className="text-lg text-gray-800">{verificationResult.major}</p>
                  </div>

                  <div>
                    <h3 className="text-sm font-semibold text-gray-500 uppercase mb-1">
                      GPA
                    </h3>
                    <p className="text-lg text-gray-800">{formatGPA(verificationResult.gpa)}</p>
                  </div>

                  <div>
                    <h3 className="text-sm font-semibold text-gray-500 uppercase mb-1">
                      Honors
                    </h3>
                    <p className="text-lg text-gray-800">
                      {getHonorsLabel(verificationResult.honors)}
                    </p>
                  </div>

                  <div>
                    <h3 className="text-sm font-semibold text-gray-500 uppercase mb-1">
                      Graduation Date
                    </h3>
                    <p className="text-lg text-gray-800">
                      {formatDate(verificationResult.graduationDate)}
                    </p>
                  </div>
                </div>

                {verificationResult.isRevoked && (
                  <div className="mt-6 bg-red-50 border-l-4 border-red-500 p-4">
                    <p className="text-red-700 font-semibold">
                      Warning: This credential has been revoked and is no longer valid.
                    </p>
                  </div>
                )}

                {!verificationResult.isIssued && (
                  <div className="mt-6 bg-yellow-50 border-l-4 border-yellow-500 p-4">
                    <p className="text-yellow-700 font-semibold">
                      This credential is pending approval and has not been issued yet.
                    </p>
                  </div>
                )}

                {verificationResult.isValid && (
                  <div className="mt-6 bg-green-50 border-l-4 border-green-500 p-4">
                    <p className="text-green-700 font-semibold">
                      This credential is valid and verified on the blockchain.
                    </p>
                  </div>
                )}
              </div>
            )}

            {!verificationResult.exists && (
              <div className="p-6">
                <p className="text-gray-600">
                  No credential found with ID {credentialId}. Please check the ID and try again.
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
