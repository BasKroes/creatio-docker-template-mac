# Dockerfile for Creatio 8.3.2 on .NET 8
# For local development on Mac/Linux

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base

# Expose HTTP and HTTPS ports
EXPOSE 5000 5002

# Install required system dependencies
RUN apt-get update && \
    apt-get -y --no-install-recommends install \
    libgdiplus \
    libc6-dev \
    curl \
    unzip && \
    apt-get clean all && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Set working directory
WORKDIR /app

# Copy Creatio application files
# NOTE: You need to extract your Creatio distribution files to ./creatio-app folder
COPY . ./

# Remove bundled .NET runtime from Creatio distribution (if exists)
# This ensures the container uses the .NET 8 runtime from the base image
RUN rm -rf /app/dotnet /app/shared 2>/dev/null || true

# Set environment variables
ENV ASPNETCORE_ENVIRONMENT=Development
ENV TZ=Europe/Amsterdam
ENV COMPlus_ThreadPool_ForceMinWorkerThreads=100
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
# Ensure system .NET is used, not any bundled version
ENV DOTNET_ROOT=/usr/share/dotnet

# Entry point
ENTRYPOINT ["dotnet", "Terrasoft.WebHost.dll"]
