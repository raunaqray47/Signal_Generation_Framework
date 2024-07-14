% AES encryption parameters
key = 'This is a key123';  % 16-byte key for AES-128
iv = 'This is an IV456';   % 16-byte initialization vector

% Convert sine wave to uint8 for encryption
S_uint8 = uint8((S + 1) * 127.5); % Normalize to [0, 255]

% Encrypt the sine wave
encryptedS = aes_encrypt(S_uint8, key, iv);

% Convert encrypted data back to double for plotting
% We use a linear index for encrypted data
encryptedS_double = double(encryptedS(1:length(t)));

% Plot encrypted sine wave
figure;
plot(t, encryptedS_double);
title('Encrypted Sine Wave');
xlabel('Time (s)');
ylabel('Amplitude');
% Function to encrypt data using AES
function encrypted = aes_encrypt(data, key, iv)
    % Ensure the data is a column vector for encryption
    data = data(:);
    
    % Create AES encryption object
    aes = javax.crypto.Cipher.getInstance('AES/CBC/PKCS5Padding');
    secretKey = javax.crypto.spec.SecretKeySpec(uint8(key), 'AES');
    ivSpec = javax.crypto.spec.IvParameterSpec(uint8(iv));
    
    % Initialize cipher for encryption
    aes.init(javax.crypto.Cipher.ENCRYPT_MODE, secretKey, ivSpec);
    
    % Encrypt data
    encrypted = aes.doFinal(data);
end

