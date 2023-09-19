# Dicoding Microservices Submission 3 (Final): Proyek Implementasi Asynchronous Communication pada Aplikasi E-Commerce App

## Objective

1. Start by setting up the project, which includes forking [this repository](https://github.com/dicodingacademy/a433-microservices/tree/proyek-pertama), and cloning the "order-service" and "shipping-service" applications from their respective branches. Prepare credential tokens and install necessary software.

2. Create a Dockerfile for each application. Then, build and push each application image to GitHub Packages.

3. Implement a server mesh with Istio on Kubernetes.

4. Deploy the RabbitMQ server on Kubernetes using Helm.

5. Deploy the applications on Kubernetes and make them available through an Istio Ingress Gateway.

## Solution

### 1. Project Setup

1. Fork the repository to your personal GitHub account, ensuring the "Copy main branch only" option is unchecked.

   ![Screenshot 2023-09-12 at 16.33.44.png](_resources/Screenshot%202023-09-12%20at%2016.33.44.png)

2. Clone the "order-service" branch from the forked repository.
   ```bash
   git clone https://github.com/<Your GitHub Username>/a433-microservices.git -b order-service order-service
   ```

3. Clone the "shipping-service" branch from the forked repository.
   ```bash
   git clone https://github.com/<Your GitHub Username>/a433-microservices.git -b shipping-service shipping-service
   ```

4. Create a GitHub personal access token with the "write:packages" access scope by following these steps:

   1. Visit [GitHub Personal Access Tokens](https://github.com/settings/tokens) webpage and click "Generate new token" -> "Generate new token (classic)" to create a new token.

      ![Screenshot 2023-09-16 at 09.16.28.png](_resources/Screenshot%202023-09-16%20at%2009.16.28.png)

   2. Give the token a name by filling the "Note" field. Then check the "write:packages" access scope to give the token permission (Note: this access scope will also include other dependent access scopes like "write:repo," etc).

      ![Screenshot 2023-09-16 at 09.23.20.png](_resources/Screenshot%202023-09-16%20at%2009.23.20.png)

   3. Scroll down to the bottom of the webpage and click the "Generate token" button. A new generated token will pop up. Copy the token.

      ![Screenshot 2023-09-16 at 09.25.32.png](_resources/Screenshot%202023-09-16%20at%2009.25.32.png)

5. Export the access token you copied before to the `GH_PACKAGES_TOKEN` environment variable.
   ```bash
   export GH_PACKAGES_TOKEN=<Your GitHub Packages Token>
   ```

6. Run a Kubernetes cluster. To run it with Docker Desktop, follow these steps:
   1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/).
   2. Open Docker Desktop and navigate to the preference panel by clicking the gear icon at the top-right corner and then click the Kubernetes option.

      ![Screenshot 2023-09-16 at 14.13.56.png](_resources/Screenshot%202023-09-16%20at%2014.13.56.png)

   3. Check "Enable Kubernetes," then click the "Apply & Restart" button.

7. Create folders for Kubernetes manifests:
   ```bash
   mkdir kubernetes kubernetes/service-service kubernetes/shipping-service
   ```

8. Install [Helm](https://helm.sh/docs/intro/install/).
9. Install [istioctl](https://istio.io/latest/docs/ops/diagnostic-tools/istioctl/).
10. Install [kubectl](https://kubernetes.io/docs/tasks/tools/).

### 2. Building and Pushing the Shipping Service Image

1. Go to the shipping service directory:
   ```bash
   cd <Project Root Directory>
   cd shipping-service
   ```

2. Create the Dockerfile:
   ```bash
   nano Dockerfile
   ```
   Copy and paste the following content:
   ```Dockerfile
   # Use Node.js version 14 as the base image
   FROM node:14

   # Set the working directory inside the container to /src
   WORKDIR /src

   # Copy package.json and package-lock.json to the working directory
   COPY package*.json ./

   # Install dependencies using npm
   RUN npm install

   # Download the wait-for-it.sh script from the repository
   RUN wget -O ./wait-for-it.sh https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh

   # Make the wait-for-it.sh script executable
   RUN chmod +x ./wait-for-it.sh

   # Copy the index.js file to the working directory
   COPY index.js ./

   # Set the environment variable PORT to 3001
   ENV PORT=3001

   # Expose the specified port
   EXPOSE $PORT

   # Define the command to run the application after waiting for RabbitMQ to start
   CMD ["sh", "-c", "./wait-for-it.sh my-rabbitmq:5672 --timeout=30 -- node index.js"]
   ```

3. Create a utility shell script for building and pushing the image:
   ```bash
   nano build_push_image.sh
   ```
   Copy and paste the following content:
   ```bash
   #!/bin/bash

   # Build Docker image
   docker build -t ghcr.io/<Your GitHub Username>/shipping-service:latest .

   # Log in to GitHub Container Registry
   echo $GH_PACKAGES_TOKEN | docker login ghcr.io -u <Your GitHub Username> --password-stdin

   # Push Docker image to GitHub Container Registry
   docker push ghcr.io/<Your GitHub Username>/shipping-service:latest
   ```

4. Run the bash script to build and push the image:
   ```bash
   bash build_push_image.sh
   ```

5. You should now see the image on your GitHub Packages dashboard. Make the visibility of the image public by following these steps:
   1. Click the name of the image.
   2. Click the "Package settings."
   3. Scroll down to the "Danger Zone" panel and click the "Change visibility" button.
   4. Select "public" under the Change visibility pop-up. Then type the name of the image in the provided field and click the "I understand the consequences, change package visibility" button.

### 3. Building and Pushing the Order Service Image
1. Go to the order service directory (the below code assumes you are at the shipping service directory):
   ```bash
   cd <Project Root Directory>
   cd order-service
   ```

2. Create the Dockerfile:
   ```bash
   nano Dockerfile
   ```
   Copy and paste the following content:
   ```Dockerfile
   # Use Node.js version 14 as the base image
   FROM node:14

   # Set the working directory inside the container to /src
   WORKDIR /src

   # Copy package.json and package-lock.json to the working directory
   COPY package*.json ./

   # Install dependencies using npm
   RUN npm install

   # Download the wait-for-it.sh script from the repository
   RUN wget -O ./wait-for-it.sh https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh

   # Make the wait-for-it.sh script executable
   RUN chmod +x ./wait-for-it.sh

   # Copy the index.js file to the working directory
   COPY index.js ./

   # Set the environment variable PORT to 3001
   ENV PORT=3000

   # Expose the specified port
   EXPOSE $PORT

   # Define the command to run the application after waiting for RabbitMQ to start
   CMD ["sh", "-c", "./wait-for-it.sh my-rabbitmq:5672 --timeout=30 -- node index.js"]
   ```

3. Create a utility shell script for building and pushing the image:
   ```bash
   nano build_push_image.sh
   ```
   Copy and paste the following content:
   ```bash
   #!/bin/bash

   # Build Docker image
   docker build -t ghcr.io/<Your GitHub Username>/order-service:latest .

   # Log in to GitHub Container Registry
   echo $GH_PACKAGES_TOKEN | docker login ghcr.io -u <Your GitHub Username> --password-stdin

   # Push Docker image to GitHub Container Registry
   docker push ghcr.io/<Your GitHub Username>/order-service:latest
   ```

4. Run the bash script to build and push the image:
   ```bash
   bash build_push_image.sh
   ```

5. You should now see the image on your GitHub Packages dashboard. Make the visibility of the image public by following these steps:
   1. Click the name of the image.
   2. Click the "Package settings."
   3. Scroll down to the "Danger Zone" panel and click the "Change visibility" button.
   4. Select "public" under the Change visibility pop-up. Then type the name of the image in the provided field and click the "I understand the consequences, change package visibility" button.

    The screenshot below displays both the pushed "shipping-service" and "order-service" images in GitHub Packages, and they are publicly visible.

   ![Screenshot 2023-09-18 at 12.45.07.png](_resources/Screenshot%202023-09-18%20at%2012.45.07.png)
### 4. Implementing Server Mesh with Istio on Kubernetes
1. Deploy Istio to Kubernetes using `istioctl`:
   ```bash
   istioctl install --set profile=demo -y
   ```

   Ensure a successful installation by verifying the following output:

   ![Screenshot 2023-09-18 at 13.02.52.png](_resources/Screenshot%202023-09-18%20at%2013.02.52.png)

2. Apply the server mesh to the default namespace:
   ```bash
   kubectl label namespace default istio-injection=enabled
   ```

### 5. Deploying RabbitMQ
1. Add the RabbitMQ Helm Repository:
   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   ```

2. Update Helm Repositories:
   ```bash
   helm repo update
   ```

3. Deploy RabbitMQ:
   ```bash
   helm install my-rabbitmq bitnami/rabbitmq
   ```

    Wait for the RabbitMQ pod to be running:

   ![Screenshot 2023-09-18 at 13.11.20.png](_resources/Screenshot%202023-09-18%20at%2013.11.20.png)

### 6. Deploying the Shipping Service Application on Kubernetes

1. Navigate to the shipping service Kubernetes manifest directory:
   ```bash
   cd <Project Root Folder>
   cd kubernetes/shipping-service
   ```

2. Create the manifest script for the deployment:
   ```bash
   nano shipping-service-deployment.yaml
   ```
   Copy and paste the following content:
   ```yaml
    apiVersion: apps/v1  # Specifies the API version being used (apps/v1 in this case).
    kind: Deployment  # Defines that this YAML describes a Kubernetes Deployment.
    metadata:
      name: shipping-service-deploy  # Deployment name for the shipping service
    spec:
      replicas: 1  # Desired number of replicas for the shipping service
      selector:
        matchLabels:
          app: shipping-service  # Selector label for the shipping service app
      template:
        metadata:
          labels:
            app: shipping-service  # Label for the shipping service app
        spec:
          containers:
            - name: shipping-service  # Container name for the shipping service
              image: ghcr.io/lareza-farhan-wanaghi/shipping-service:latest  # Container image for the shipping service
              ports:
                - containerPort: 3001  # Port on which the shipping service container listens
              env:
                - name: AMQP_PASSWORD  # Environment variable for AMQP password
                  valueFrom:
                    secretKeyRef:
                      name: my-rabbitmq  # Secret name for RabbitMQ credentials
                      key: rabbitmq-password  # Secret key for RabbitMQ password
                - name: AMQP_URL  # Environment variable for AMQP URL
                  value: "amqp://user:$(AMQP_PASSWORD)@my-rabbitmq:5672"  # Value for the AMQP URL

   ```

3. Create the manifest script for the service:
   ```bash
   nano shipping-service-service.yaml
   ```
   Copy and paste the following content:
   ```yaml
    apiVersion: v1  # Specifies the API version being used (v1 in this case).
    kind: Service   # Defines that this YAML describes a Kubernetes Service.
    metadata:
      name: shipping-service-svc  # Specifies the name of the Service.
    spec:
      selector:
        app: shipping-service  # Defines the selector to identify the pods targeted by this service.
      ports:
        - port: 3001 # Specifies the port number (3001 in this case).

   ```

4. Deploy the manifest:
   ```bash
   kubectl apply -f .
   ```

5. Check the pod logs for any errors to ensure correct integration of the application with RabbitMQ.
   ```bash
   kubectl logs $(kubectl get pods -l app=shipping-service -o jsonpath="{.items[0].metadata.name}")
   ```

   You should see something similar to this (wait until the "Server running at <PORT>" message appears):

   ![Screenshot 2023-09-18 at 13.12.43.png](_resources/Screenshot%202023-09-18%20at%2013.12.43.png)

### 7. Deploying the Order Service Application on Kubernetes

1. Navigate to the order service Kubernetes manifest directory:
   ```bash
   cd <Project Root Directory>
   cd kubernetes/order-service
   ```

2. Create the manifest for the deployment:
   ```bash
   nano order-service-deployment.yaml
   ```
   Copy and paste the following content:
   ```yaml
    apiVersion: apps/v1 # Specifies the API version being used (apps/v1 in this case).
    kind: Deployment # Defines the Kubernetes resource type as a Deployment.
    metadata:
      name: order-service-deploy  # Name of the Deployment resource
    spec:
      replicas: 1  # Specifies the desired number of replicas for the Deployment
      selector:
        matchLabels:
          app: order-service  # Selects Pods based on the app label with the value order-service
      template:
        metadata:
          labels:
            app: order-service  # Labels the Pods created by this template with the app label and value order-service
        spec:
          containers:
            - name: order-service  # Name of the container within the Pod
              image: ghcr.io/lareza-farhan-wanaghi/order-service:latest  # Docker image used for the container
              ports:
                - containerPort: 3000  # Port on which the container listens for incoming traffic
              env:
                - name: AMQP_PASSWORD  # Environmental variable name for the RabbitMQ password
                  valueFrom:
                    secretKeyRef:
                      name: my-rabbitmq  # Name of the Secret containing the RabbitMQ password
                      key: rabbitmq-password  # Key within the Secret to retrieve the RabbitMQ password
                - name: AMQP_URL  # Environmental variable name for the RabbitMQ URL
                  value: "amqp://user:$(AMQP_PASSWORD)@my-rabbitmq:5672"  # Value for the RabbitMQ URL, including the username, password, and host

   ```

3. Create the manifest for the service:
   ```bash
   nano order-service-service.yaml
   ```
   Copy and paste the following content:
   ```yaml
    apiVersion: v1 # Specifies the API version being used (v1 in this case).
    kind: Service # Defines the Kubernetes resource type as a Service.
    metadata:
      name: order-service-svc  # Name assigned to this Service resource.
    spec:
      selector:
        app: order-service  # Selects pods labeled with 'app: order-service'.
      ports:
        - port: 3000  # Exposes the Service on port 3000 using TCP protocol.

   ```

4. Create the manifest for the gateway:
   ```bash
   nano order-service-gateway.yaml
   ```
   Copy and paste the following content:
   ```yaml
    apiVersion: networking.istio.io/v1alpha3 # Specifies the API version being used (networking.istio.io/v1alpha3 in this case).
    kind: Gateway # Defines the Kubernetes resource type as a Gateway.
    metadata:
      name: order-service-gw  # Name of the Istio Gateway for the order service.
    spec:
      selector:
        istio: ingressgateway  # Selector for the ingress gateway.
      servers:
        - port:
            number: 80  # Port number for HTTP traffic.
            name: http  # Name of the HTTP protocol.
            protocol: HTTP  # Protocol used for this port (HTTP).
          hosts:
            - "*"  # Accepting requests from all hosts.

   ```

5. Create the manifest file for the virtual service:
   ```bash
   nano order-service-virtualservice.yaml
   ```
   Copy and paste the following content:
   ```yaml
    apiVersion: networking.istio.io/v1alpha3  # Specifies the API version being used (networking.istio.io/v1alpha3 in this case).
    kind: VirtualService  # Defines that this YAML describes a VirtualService Service.
    metadata:
      name: order-service-vs  # Name of the VirtualService
    spec:
      hosts:
        - "*"  # Match all hosts
      gateways:
        - order-service-gw  # Use the order-service-gw gateway
      http:
        - match:
            - uri:
                exact: "/order"  # Match exact URI "/order"
          route:
            - destination:
                host: order-service-svc  # Send traffic to   order-service-svc
                port:
                  number: 3000  # Use port 3000

   ```

6. Deploy the manifest:
   ```bash
   kubectl apply -f .
   ```

7. Check the pod logs for any errors to ensure correct integration of the application with RabbitMQ:
   ```bash
   kubectl logs $(kubectl get pods -l app=order-service -o jsonpath="{.items[0].metadata.name}")
   ```

   You should see something similar to this (wait until the "Server running at <PORT>" message appears):

   ![Screenshot 2023-09-18 at 13.26.27.png](_resources/Screenshot%202023-09-18%20at%2013.26.27.png)

### 8. Testing the Application and Monitoring the Queue Using RabbitMQ Management Interface

1. Port forward the RabbitMQ management interface (use `sudo` if needed):
   ```bash
   kubectl port-forward --namespace default svc/my-rabbitmq 15672:15672
   ```

2. Open your web browser and visit `localhost:15672`. You will be greeted with the login page:

   ![Screenshot 2023-09-18 at 13.31.51.png](_resources/Screenshot%202023-09-18%20at%2013.31.51.png)

3. Log in with the default credentials. Use "user" as the username and the value obtained from the following code as the password:
   ```bash
   echo "$(kubectl get secret --namespace default my-rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 -d)"
   ```

   Once logged in, you will see the RabbbitMQ overview dashboard:

   ![Screenshot 2023-09-18 at 13.34.16.png](_resources/Screenshot%202023-09-18%20at%2013.34.16.png)

4. Navigate to the "Queue and Stream" tab. You should find a queue named "order," which your application created when it started. Click on the "order" queue to see its dashboard:

   ![Screenshot 2023-09-18 at 13.38.28.png](_resources/Screenshot%202023-09-18%20at%2013.38.28.png)

5. Return to the terminal and port forward the `istio-ingressgateway` service in the `istio-system` namespace on port 80 to make the application gateway accessible (use `sudo` if needed):
   ```bash
   kubectl port-forward svc/istio-ingressgateway -n istio-system 80:80
   ```

6. Execute the following command to send ten POST requests to the order service application and test the application:
   ```bash
   for i in {1..10}; do
     curl -X POST -H "Content-Type: application/json" -d '{
       "order": {
           "book_name": "book_name_'$i'",
           "author": "author_'$i'",
           "buyer": "buyer_'$i'",
           "shipping_address": "shipping_address_'$i'"
       }
     }' http://localhost:80/order
   done
   ```

   Check the order queue dashboard; you should see green lines indicating activity:

   ![Screenshot 2023-09-18 at 13.43.24.png](_resources/Screenshot%202023-09-18%20at%2013.43.24.png)

   Check the order service pod logs:
   ```bash
   kubectl logs $(kubectl get pods -l app=order-service -o jsonpath="{.items[0].metadata.name}")
   ```

   You should see output similar to this:

   ![Screenshot 2023-09-18 at 14.07.46.png](_resources/Screenshot%202023-09-18%20at%2014.07.46.png)

   	Check the shipping service pod logs 
    ```bash
    kubectl logs $(kubectl get pods -l app=shipping-service -o jsonpath="{.items[0].metadata.name}")
    ```

    You should see output similar to this:

    ![Screenshot 2023-09-18 at 14.08.58.png](_resources/Screenshot%202023-09-18%20at%2014.08.58.png)