import { Link } from 'react-router-dom';

export const Home = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="container mx-auto px-4 py-16">
        <div className="text-center mb-16">
          <h1 className="text-6xl font-bold text-gray-900 mb-4">
            Academic Proof
          </h1>
          <p className="text-2xl text-gray-700 mb-2">
            Decentralized Academic Credentials System
          </p>
          <p className="text-lg text-gray-600">
            Secure, tamper-proof academic credentials on the blockchain
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          <Link
            to="/student"
            className="bg-white rounded-xl shadow-lg p-8 hover:shadow-2xl transition transform hover:-translate-y-1"
          >
            <div className="text-5xl mb-4">🎓</div>
            <h2 className="text-2xl font-bold text-gray-800 mb-4">Students</h2>
            <p className="text-gray-600 mb-4">
              View and manage your academic credentials stored as Soulbound NFTs
            </p>
            <div className="text-blue-600 font-semibold">
              View Credentials →
            </div>
          </Link>

          <Link
            to="/university"
            className="bg-white rounded-xl shadow-lg p-8 hover:shadow-2xl transition transform hover:-translate-y-1"
          >
            <div className="text-5xl mb-4">🏛️</div>
            <h2 className="text-2xl font-bold text-gray-800 mb-4">Universities</h2>
            <p className="text-gray-600 mb-4">
              Issue verifiable academic credentials with multi-signature approval
            </p>
            <div className="text-blue-600 font-semibold">
              Issue Credentials →
            </div>
          </Link>

          <Link
            to="/verifier"
            className="bg-white rounded-xl shadow-lg p-8 hover:shadow-2xl transition transform hover:-translate-y-1"
          >
            <div className="text-5xl mb-4">✓</div>
            <h2 className="text-2xl font-bold text-gray-800 mb-4">Verifiers</h2>
            <p className="text-gray-600 mb-4">
              Instantly verify the authenticity of academic credentials
            </p>
            <div className="text-blue-600 font-semibold">
              Verify Credentials →
            </div>
          </Link>
        </div>

        <div className="mt-16 bg-white rounded-xl shadow-lg p-8 max-w-4xl mx-auto">
          <h2 className="text-3xl font-bold text-gray-800 mb-6 text-center">Key Features</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="flex items-start">
              <div className="text-3xl mr-4">🔒</div>
              <div>
                <h3 className="text-xl font-semibold text-gray-800 mb-2">Tamper-Proof</h3>
                <p className="text-gray-600">
                  Credentials stored on blockchain cannot be altered or forged
                </p>
              </div>
            </div>

            <div className="flex items-start">
              <div className="text-3xl mr-4">⚡</div>
              <div>
                <h3 className="text-xl font-semibold text-gray-800 mb-2">Instant Verification</h3>
                <p className="text-gray-600">
                  Employers can verify credentials in seconds
                </p>
              </div>
            </div>

            <div className="flex items-start">
              <div className="text-3xl mr-4">🔑</div>
              <div>
                <h3 className="text-xl font-semibold text-gray-800 mb-2">Multi-Signature</h3>
                <p className="text-gray-600">
                  Universities can require multiple approvers for security
                </p>
              </div>
            </div>

            <div className="flex items-start">
              <div className="text-3xl mr-4">🎯</div>
              <div>
                <h3 className="text-xl font-semibold text-gray-800 mb-2">Soulbound NFTs</h3>
                <p className="text-gray-600">
                  Non-transferable credentials ensure authenticity
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-12 text-center">
          <div className="inline-block bg-blue-100 rounded-lg px-6 py-3">
            <p className="text-sm text-gray-700">
              <span className="font-semibold">Network:</span> Sepolia Testnet
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
