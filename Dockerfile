FROM bash:5.0.11

CMD ["bash", "-c", "while true; do (( i++ )); echo 'Sleep $i.'; sleep 3; done"]
