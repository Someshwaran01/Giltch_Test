import hashlib

# Test admin credentials
password = 'admin123'
hash_value = hashlib.sha256(password.encode()).hexdigest()

print("=" * 60)
print("ADMIN CREDENTIALS TEST")
print("=" * 60)
print(f"Username: admin")
print(f"Password: {password}")
print(f"Expected Hash: 240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9")
print(f"Generated Hash: {hash_value}")
print(f"Match: {hash_value == '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9'}")
print(f"Hash Length: {len(hash_value)} chars")
print(f"Is Hex: {all(c in '0123456789abcdef' for c in hash_value.lower())}")

print("\n" + "=" * 60)
print("TESTING PASSWORD VERIFICATION LOGIC")
print("=" * 60)

# Simulate the backend verification
password_hash = '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9'
password_input = 'admin123'

# Check if it's a SHA256 hash (64 characters, all hex)
if len(password_hash) == 64 and all(c in '0123456789abcdef' for c in password_hash.lower()):
    print(f"✓ Detected as SHA256 hash")
    input_hash = hashlib.sha256(password_input.encode()).hexdigest()
    if password_hash == input_hash:
        print(f"✓ Password verification PASSED")
    else:
        print(f"✗ Password verification FAILED")
        print(f"  Expected: {password_hash}")
        print(f"  Got: {input_hash}")
else:
    print(f"✗ Not detected as SHA256 hash")

print("\n" + "=" * 60)
print("LEADER CREDENTIALS TEST")
print("=" * 60)
password2 = 'leader123'
hash_value2 = hashlib.sha256(password2.encode()).hexdigest()
print(f"Username: leader1")
print(f"Password: {password2}")
print(f"Expected Hash: 6b4b7f0b81d0b3494dd853bc45c0605fa99125c93de8a9850cbc62b2f6d52d13")
print(f"Generated Hash: {hash_value2}")
print(f"Match: {hash_value2 == '6b4b7f0b81d0b3494dd853bc45c0605fa99125c93de8a9850cbc62b2f6d52d13'}")
