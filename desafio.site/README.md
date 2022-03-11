# DevOps Challenge | Desafio DevOps

## _Desafio.site Project_

**_by [T. Fontoura](https://www.linkedin.com/in/tom-fontoura/)_**

A company has challenged me to automate the creation of Docker containers in an AWS instance, installing Wordpress with Apache, adding Nginx as a reverse proxy.

I accepted the challenge and, to improve it a little, I decided to develop a small project (which did not take more than a day) that allowed a simple installation, with few instructions and the objective of reducing the installation to just one command line. That way the whole process would be more user-friendly. I named the project _desafio.site_, as "desafio" means challenge in Portuguese.

***

## Installation

1. Create an EC-2 AWS instance with the following image

>Ubuntu Server 20.04 LTS (HVM), SSD Volume Type - ami-04505e74c0741db8d (64-bit x86)
2. Add the instance to a security group with ports 80, 443 e 22 open

3. Access the instance by SSH

4. Run the following command line:<br>

```sh
curl https://desafio.site/init.sh | sudo bash
```
Wait until it finishes and that's all!

***

## How it was done

* I created an S3 bucket S3 with the name desafio.site and configured it as an static website, the web address as _desafio.site.s3-website-us-east-1.amazonaws.com_. I could have utilized that domain name, but I decided to move one step further, in order to demonstrate my domains and DNS knowledge.
* Registered domain [desafio.site](https://desafio.site)
* Created a CNAME register in its DNS, pointing [_desafio.site_](https://desafio.site) to _desafio.site.s3-website-us-east-1.amazonaws.com_
* Wrote the automation shell script [init.sh](https://desafio.site/init.sh) and put it in the website
* Created a [robots.txt](https://desafio.site/robots.txt) to tell robots not to crawl it, in order for the website not be indexed by search engines

***

## Notes

As this is a quick project for evaluation, security issues and other points were not taken into account, such as:

* We could create random passwords; we could automatically create, using lambda and Cloudflare API, a subdomain of <i>desafio.site</i> for the new server (name that could be entered manually, and thus create folders for it in EFS), etc.

I did not use RDS or EFS so that the project could be more easily reproduced on the evaluator's internal server. But in a project like this for production, I do it a little differently:


I create custom images with docker installed and already with EFS in fstab, mounted. Everything I need is already in that image.
I use RDS or a master+slave cluster or Galera as db.

Anyway, this is a project done in a short time (~12h). It's not perfect, but I hope it serves as an assessment of skills and knowledge.


***

## License

Copyright T. Fontoura 2022 - All rights reserved |
Contact: [T. Fontoura's LinkedIn profile page](https://www.linkedin.com/in/tom-fontoura/)
