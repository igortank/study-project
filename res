NAME: wordpress
LAST DEPLOYED: Sat Apr 15 10:02:00 2023
NAMESPACE: project
STATUS: pending-install
REVISION: 1
HOOKS:
---
# Source: wordpress/templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "wordpress-test-connection"
  labels:
    helm.sh/chart: wordpress-1.0.2
    app.kubernetes.io/name: wordpress
    app.kubernetes.io/instance: wordpress
    app.kubernetes.io/version: "1.0.2"
    app.kubernetes.io/managed-by: Helm
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['wordpress:80']
  restartPolicy: Never
MANIFEST:
---
# Source: wordpress/templates/storageClass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-wordpress
provisioner: cluster.local/nfs-nfs-subdir-external-provisioner
parameters:
  onDelete: "retain"
  pathPattern: "/IgorBudarkevich/wordpress/"
---
# Source: wordpress/templates/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wordpress-pvc
spec:
  accessModes:
      - ReadWriteMany
  resources:
    requests:
      storage: 3Gi
  storageClassName: nfs-wordpress
---
# Source: wordpress/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  labels:
    helm.sh/chart: wordpress-1.0.2
    app.kubernetes.io/name: wordpress
    app.kubernetes.io/instance: wordpress
    app.kubernetes.io/version: "1.0.2"
    app.kubernetes.io/managed-by: Helm
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: wordpress
    app.kubernetes.io/instance: wordpress
---
# Source: wordpress/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: wordpress-preview
  labels:
    helm.sh/chart: wordpress-1.0.2
    app.kubernetes.io/name: wordpress
    app.kubernetes.io/instance: wordpress
    app.kubernetes.io/version: "1.0.2"
    app.kubernetes.io/managed-by: Helm
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: wordpress
    app.kubernetes.io/instance: wordpress
---
# Source: wordpress/templates/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress
  labels:
    helm.sh/chart: wordpress-1.0.2
    app.kubernetes.io/name: wordpress
    app.kubernetes.io/instance: wordpress
    app.kubernetes.io/version: "1.0.2"
    app.kubernetes.io/managed-by: Helm
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
    - host: "wordpress.k8s-2.sa"
      http:
        paths:
          - path: /
            pathType: ImplementationSpecific
            backend:
              service:
                name: wordpress
                port:
                  number: 80
---
# Source: wordpress/templates/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress-preview
  labels:
    helm.sh/chart: wordpress-1.0.2
    app.kubernetes.io/name: wordpress
    app.kubernetes.io/instance: wordpress
    app.kubernetes.io/version: "1.0.2"
    app.kubernetes.io/managed-by: Helm
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
    - host: "wordpress-preview.k8s-2.sa"
      http:
        paths:
          - path: /
            pathType: ImplementationSpecific
            backend:
              service:
                name: wordpress-preview
                port:
                  number: 80
---
# Source: wordpress/templates/deployment.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: wordpress
  labels:
    helm.sh/chart: wordpress-1.0.2
    app.kubernetes.io/name: wordpress
    app.kubernetes.io/instance: wordpress
    app.kubernetes.io/version: "1.0.2"
    app.kubernetes.io/managed-by: Helm
spec:
  replicas: 1
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: wordpress
      app.kubernetes.io/instance: wordpress
  strategy:
    blueGreen:
      activeService: wordpress
      previewService: wordpress-preview
  template:
    metadata:
      labels:
        app.kubernetes.io/name: wordpress
        app.kubernetes.io/instance: wordpress
    spec:
      serviceAccountName: default
      securityContext:
        {}
      containers:
        - name: wordpress
          securityContext:
            {}
          image: "docker pull budarkevichigor/wordpress:1.0.2"
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
            limits:
              cpu: 1000m
              memory: 1Gi
            requests:
              cpu: 200m
              memory: 400Mi
          env:
          - name: WORDPRESS_DB_HOST
            value: 192.168.201.2:3306
          - name: WORDPRESS_DB_USER
            value: db_admin
          - name: WORDPRESS_DB_PASSWORD
            value: db_admin
          - name: WORDPRESS_DB_NAME
            value: wordpress
          volumeMounts:
          - name: wordpress-pvc-app
            mountPath: /var/www/html/wp-content/
            subPath: wp-content
      volumes:
      - name: wordpress-pvc-app
        persistentVolumeClaim:
          claimName: wordpress-pvc

NOTES:
1. Get the application URL by running these commands:
  http://wordpress.k8s-2.sa/
