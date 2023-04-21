# Build image
FROM rust:1-slim-bullseye as builder

WORKDIR /app
COPY . /app

ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

RUN apt-get update && apt-get install -y \
    libopus-dev cmake wget
RUN cargo build --release && \
    wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /yt-dlp && \
    chmod +x /yt-dlp


FROM alpine:3 AS compressor

COPY --from=mwader/static-ffmpeg:6.0 /ffmpeg /ffmpeg
COPY --from=builder  /app/target/release/parrot /parrot

RUN apk add upx wget && \
    upx --lzma --best /parrot && \
    upx -1 /ffmpeg


# Release image
FROM debian:bullseye-slim

COPY --from=compressor /ffmpeg /bin/
COPY --from=compressor /parrot /bin/
COPY --from=builder /yt-dlp /bin/

RUN apt-get update && apt-get install -y python3

USER 1000

CMD ["parrot"]
