
## Configure AWS

* Set Environmental variables
  ```
  $ export AWS_ACCESS_KEY_ID="anaccesskey"
  $ export AWS_SECRET_ACCESS_KEY="asecretkey"
  $ export AWS_REGION="ap-south-1"
  ```
* After that run it.
  ```
  $ terraform plan
  ```

OR

* Create site key / secret key for your aws account and config on your machine
```
techno-384@techno384-Latitude-3410:~$ aws configure
AWS Access Key ID [****************F3BI]: XXX
AWS Secret Access Key [****************mL42]: XXX
Default region name [ap-south-1]: ap-south-1
Default output format [None]: JSON


techno-384@techno384-Latitude-3410:~$ cat ~/.aws/config 
[default]
region = ap-south-1
output = JSON

```


## 