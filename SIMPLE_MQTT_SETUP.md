# Simple MQTT Setup for Tabi Backend

This is a simplified MQTT authentication setup for the Tabi Backend project.

## What's Configured

- **MQTT User**: `tabi-backend`
- **Password**: `TabiMQTT2024!`
- **Permissions**: Full access to all topics (simple setup)
- **Anonymous Access**: Disabled for security

## Files

- `config.json` - Contains MQTT credentials for the backend server
- `mosquitto_acl` - Simple ACL giving full access to tabi-backend user
- `Dockerfile` - Automatically creates the password file during build

## How It Works

1. The Docker build process creates a Mosquitto password file with the `tabi-backend` user
2. Mosquitto is configured to require authentication (no anonymous access)
3. The backend server connects using the credentials in `config.json`

## To Use

Simply build and run the container:

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up
```

## Testing MQTT Connection

You can test the MQTT connection using the test container:

```bash
# Start the test container
docker-compose --profile testing up mqtt-test

# Test publishing a message
docker exec tabi-mqtt-test mosquitto_pub -h tabi-backend -u tabi-backend -P "TabiMQTT2024!" -t "test/hello" -m "Hello World"

# Test subscribing to messages
docker exec tabi-mqtt-test mosquitto_sub -h tabi-backend -u tabi-backend -P "TabiMQTT2024!" -t "test/#"
```

## Security Note

This is a simple setup for development/testing. For production:
- Use environment variables for credentials
- Use more complex passwords
- Implement proper topic-level permissions in the ACL file