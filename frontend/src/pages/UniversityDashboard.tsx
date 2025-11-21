import { useState, useEffect } from 'react';
import { useWallet } from '../contexts/WalletContext';
import { DegreeType, Honors, DEGREE_TYPE_LABELS, HONORS_LABELS } from '../types';

export const UniversityDashboard = () => {
  const { account, academicCredentialContract, universityRegistryContract } = useWallet();
  const [universityId, setUniversityId] = useState<number | null>(null);
  const [isAuthorized, setIsAuthorized] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const [formData, setFormData] = useState<{
    studentAddress: string;
    degreeType: number;
    major: string;
    gpa: string;
    honors: number;
    graduationDate: string;
    metadataURI: string;
  }>({
    studentAddress: '',
    degreeType: DegreeType.BACHELOR,
    major: '',
    gpa: '',
    honors: Honors.NONE,
    graduationDate: '',
    metadataURI: '',
  });

  useEffect(() => {
    const checkAuthorization = async () => {
      if (!account || !universityRegistryContract) return;

      try {
        const uniId = await universityRegistryContract.getUniversityByAdmin(account);
        if (Number(uniId) > 0) {
          setUniversityId(Number(uniId));
          const authorized = await universityRegistryContract.isAuthorizedSigner(uniId, account);
          setIsAuthorized(authorized);
        }
      } catch (err) {
        console.error('Error checking authorization:', err);
      }
    };

    checkAuthorization();
  }, [account, universityRegistryContract]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!academicCredentialContract || !universityId) return;

    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      const gpaScaled = Math.round(parseFloat(formData.gpa) * 100);
      const graduationTimestamp = Math.floor(new Date(formData.graduationDate).getTime() / 1000);

      const tx = await academicCredentialContract.requestCredential(
        formData.studentAddress,
        universityId,
        formData.degreeType,
        formData.major,
        gpaScaled,
        formData.honors,
        graduationTimestamp,
        formData.metadataURI || 'ipfs://'
      );

      await tx.wait();
      setSuccess('Credential request submitted successfully!');
      setFormData({
        studentAddress: '',
        degreeType: DegreeType.BACHELOR,
        major: '',
        gpa: '',
        honors: Honors.NONE,
        graduationDate: '',
        metadataURI: '',
      });
    } catch (err) {
      console.error('Error issuing credential:', err);
      setError((err as Error).message || 'Failed to issue credential');
    } finally {
      setLoading(false);
    }
  };

  if (!account) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="bg-white p-8 rounded-lg shadow-md text-center">
          <h2 className="text-2xl font-bold text-gray-800 mb-4">University Dashboard</h2>
          <p className="text-gray-600 mb-6">Please connect your wallet to continue</p>
        </div>
      </div>
    );
  }

  if (!isAuthorized) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="bg-white p-8 rounded-lg shadow-md text-center">
          <h2 className="text-2xl font-bold text-gray-800 mb-4">Access Denied</h2>
          <p className="text-gray-600 mb-6">
            Your account is not authorized to issue credentials.
            {universityId && ` (University ID: ${universityId})`}
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="container mx-auto px-4 max-w-2xl">
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-800 mb-2">Issue Credential</h1>
          <p className="text-gray-600">University ID: {universityId}</p>
        </div>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            {error}
          </div>
        )}

        {success && (
          <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
            {success}
          </div>
        )}

        <form onSubmit={handleSubmit} className="bg-white p-8 rounded-lg shadow-md">
          <div className="mb-4">
            <label className="block text-gray-700 font-semibold mb-2">
              Student Address
            </label>
            <input
              type="text"
              value={formData.studentAddress}
              onChange={(e) => setFormData({ ...formData, studentAddress: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="0x..."
              required
            />
          </div>

          <div className="mb-4">
            <label className="block text-gray-700 font-semibold mb-2">
              Degree Type
            </label>
            <select
              value={formData.degreeType}
              onChange={(e) => setFormData({ ...formData, degreeType: Number(e.target.value) })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {Object.entries(DEGREE_TYPE_LABELS).map(([value, label]) => (
                <option key={value} value={value}>{label}</option>
              ))}
            </select>
          </div>

          <div className="mb-4">
            <label className="block text-gray-700 font-semibold mb-2">
              Major
            </label>
            <input
              type="text"
              value={formData.major}
              onChange={(e) => setFormData({ ...formData, major: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Computer Science"
              required
            />
          </div>

          <div className="mb-4">
            <label className="block text-gray-700 font-semibold mb-2">
              GPA (0.00 - 4.00)
            </label>
            <input
              type="number"
              step="0.01"
              min="0"
              max="4.00"
              value={formData.gpa}
              onChange={(e) => setFormData({ ...formData, gpa: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="3.85"
              required
            />
          </div>

          <div className="mb-4">
            <label className="block text-gray-700 font-semibold mb-2">
              Honors
            </label>
            <select
              value={formData.honors}
              onChange={(e) => setFormData({ ...formData, honors: Number(e.target.value) })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {Object.entries(HONORS_LABELS).map(([value, label]) => (
                <option key={value} value={value}>{label}</option>
              ))}
            </select>
          </div>

          <div className="mb-4">
            <label className="block text-gray-700 font-semibold mb-2">
              Graduation Date
            </label>
            <input
              type="date"
              value={formData.graduationDate}
              onChange={(e) => setFormData({ ...formData, graduationDate: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>

          <div className="mb-6">
            <label className="block text-gray-700 font-semibold mb-2">
              Metadata URI (optional)
            </label>
            <input
              type="text"
              value={formData.metadataURI}
              onChange={(e) => setFormData({ ...formData, metadataURI: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="ipfs://..."
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? 'Issuing Credential...' : 'Issue Credential'}
          </button>
        </form>
      </div>
    </div>
  );
};
