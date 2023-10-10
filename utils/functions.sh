with_retry() {
  local cmd="$1"
  local max_attempts="$2"
  local delay="$3"
  local attempt=1

  until $cmd || [ "$attempt" -ge "$max_attempts" ]; do
    echo "Attempt $attempt failed. Retrying in $delay seconds..."
    sleep "$delay"
    attempt=$((attempt + 1))
  done
}
