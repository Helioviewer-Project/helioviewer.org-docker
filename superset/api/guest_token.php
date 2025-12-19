<?php
/**
 * Guest Token Generator for Superset Embedded Dashboard
 *
 * Generates JWT guest tokens using RSA private key signature (RS256).
 * More secure than symmetric keys - uses public/private key pair.
 *
 * No authentication required - generates guest tokens for anyone.
 */

// ============================================================================
// CORS Headers
// ============================================================================
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: OPTIONS, POST');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Handle OPTIONS preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ============================================================================
// CONFIGURATION - Load from environment variables
// ============================================================================

// Path to RSA private key file (keep this secure!)
$PRIVATE_KEY_PATH = getenv('SUPERSET_GUEST_PK') ?: __DIR__ . '/embedded_private.pem';

// This should match GUEST_TOKEN_JWT_AUDIENCE in Superset config.py
$JWT_AUDIENCE = getenv('SUPERSET_GUEST_JWT_AUD') ?: 'helioviewer_audience';

// Allowed dashboard IDs (JSON array)
$ALLOWED_DASHBOARDS_JSON = getenv('SUPERSET_GUEST_ALLOWED_DASHBOARDS') ?: '[]';
$ALLOWED_DASHBOARDS = json_decode($ALLOWED_DASHBOARDS_JSON, true);

if (!is_array($ALLOWED_DASHBOARDS)) {
    throw new Exception("SUPERSET_GUEST_ALLOWED_DASHBOARDS must be a valid JSON array");
}

// Token expiration time (in seconds) - 5 minutes default
$TOKEN_EXPIRATION = 300;

// ============================================================================
// JWT Helper Functions
// ============================================================================

/**
 * Base64 URL encode
 */
function base64UrlEncode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

/**
 * Create JWT token using RSA signature (RS256)
 */
function createJWT($payload, $privateKeyPath, $algorithm = 'RS256') {
    // Read private key
    $privateKey = file_get_contents($privateKeyPath);
    if ($privateKey === false) {
        throw new Exception("Failed to read private key from: $privateKeyPath");
    }

    // Load private key resource
    $keyResource = openssl_pkey_get_private($privateKey);
    if ($keyResource === false) {
        throw new Exception("Failed to load private key. Error: " . openssl_error_string());
    }

    // Header
    $header = [
        'typ' => 'JWT',
        'alg' => $algorithm
    ];

    $headerEncoded = base64UrlEncode(json_encode($header));
    $payloadEncoded = base64UrlEncode(json_encode($payload));

    // Data to sign
    $dataToSign = $headerEncoded . '.' . $payloadEncoded;

    // Sign with RSA private key
    $signature = '';
    $success = openssl_sign($dataToSign, $signature, $keyResource, OPENSSL_ALGO_SHA256);

    if (!$success) {
        throw new Exception("Failed to sign JWT. Error: " . openssl_error_string());
    }

    // Note: In PHP 8.0+, key resources are automatically freed, no need to call openssl_free_key()

    $signatureEncoded = base64UrlEncode($signature);

    // JWT token
    return $headerEncoded . '.' . $payloadEncoded . '.' . $signatureEncoded;
}

/**
 * Generate guest token payload
 */
function generateGuestTokenPayload($dashboardIds, $audience, $expiration) {
    $now = time();

    // Build resources array - empty if no dashboard IDs provided
    $resources = [];
    if ($dashboardIds !== null) {
        // Ensure $dashboardIds is an array
        if (!is_array($dashboardIds)) {
            $dashboardIds = [$dashboardIds];
        }

        // Add each dashboard ID to resources
        foreach ($dashboardIds as $dashboardId) {
            $resources[] = [
                "type" => "dashboard",
                "id" => $dashboardId
            ];
        }
    }

    return [
        // User information
        'user' => [
            'username' => 'guest_' . uniqid(),
            'first_name' => 'Guest',
            'last_name' => 'User'
        ],

        // Resources this token grants access to
        'resources' => $resources,

        // Row Level Security rules (empty = no restrictions)
        'rls_rules' => [],

        // JWT standard claims
        'aud' => $audience,
        'iat' => $now,
        'exp' => $now + $expiration,
        'type' => 'guest'
    ];
}

// ============================================================================
// Main Execution
// ============================================================================

try {
    // Only allow POST requests
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode([
            'error' => 'Method not allowed. Use POST.'
        ]);
        exit;
    }

    // Get dashboard ID(s) from request body (optional)
    $input = json_decode(file_get_contents('php://input'), true);
    $DASHBOARD_ID = $input['dashboard_id'] ?? null;

    // Validate dashboard ID(s) against allowed list only if provided and allowed list is not empty
    if ($DASHBOARD_ID !== null && !empty($ALLOWED_DASHBOARDS)) {
        // Ensure $DASHBOARD_ID is an array for consistent validation
        $dashboardIdsToValidate = is_array($DASHBOARD_ID) ? $DASHBOARD_ID : [$DASHBOARD_ID];

        // Check each dashboard ID against the allowed list
        foreach ($dashboardIdsToValidate as $id) {
            if (!in_array($id, $ALLOWED_DASHBOARDS)) {
                http_response_code(403);
                echo json_encode([
                    'error' => "Dashboard ID '$id' not allowed",
                    'success' => false
                ]);
                exit;
            }
        }
    }

    // Validate configuration
    if (!file_exists($PRIVATE_KEY_PATH)) {
        throw new Exception("Private key file not found at: $PRIVATE_KEY_PATH");
    }

    // Generate token payload
    $payload = generateGuestTokenPayload($DASHBOARD_ID, $JWT_AUDIENCE, $TOKEN_EXPIRATION);

    // Create JWT token using RSA private key
    $token = createJWT($payload, $PRIVATE_KEY_PATH);

    // Return the guest token
    echo json_encode([
        'token' => $token,
        'success' => true
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => $e->getMessage(),
        'success' => false
    ]);

    // Log the error
    error_log("Superset guest token error: " . $e->getMessage());
}
