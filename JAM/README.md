# IBM Bob Java Modernization Lab

This folder contains the IBM Bob Java Modernization lab based on the ModResorts Java 8 application.

## Interactive Lab Guide

Open the lab guide here:

[IBM Bob Java Modernization Lab - ModResorts](./IBM_Bob_Java_Modernization_Lab_ModResorts_FINAL_v5.html)

> Note: GitHub may display the HTML source instead of rendering it as a webpage.
> For the best experience, download the HTML file and open it in a browser, or publish it using GitHub Pages.

## Lab Files

| File | Description |
|---|---|
| `IBM_Bob_Java_Modernization_Lab_ModResorts_FINAL_v5.html` | Interactive step-by-step Java modernization lab guide |
| `modresorts-twas-j8.zip` | Original Java 8 ModResorts application used in the lab |
| `modresorts-lab-prereq.sh` | Prerequisite and environment validation script |

## Lab Objective

The goal of this lab is to demonstrate how IBM Bob can assist with Java application modernization.

The lab walks through:

- Preparing and validating the lab environment
- Opening the legacy Java application in Bob IDE
- Reviewing the existing Java 8 application
- Assessing application structure and dependencies
- Identifying modernization opportunities
- Modernizing the application
- Reviewing Bob-generated changes
- Building and testing the application
- Verifying the modernized application

## Application

The lab uses the **ModResorts** sample application.

The starting application is based on an older Java and WebSphere environment and is used to demonstrate a typical modernization workflow.

## Getting Started

1. Download or clone this repository.
2. Navigate to the `JAM` folder.
3. Run the prerequisite script:

```bash
chmod +x modresorts-lab-prereq.sh
./modresorts-lab-prereq.sh
```

4. Unzip the application:

```bash
unzip modresorts-twas-j8.zip
```

5. In Bob IDE, open the following folder:

```text
JavaModLab/modresorts-twas-j8
```

6. Follow the instructions in the interactive lab guide.

## IBM Bob

IBM Bob is used throughout this lab to assist with:

- Code understanding
- Application assessment
- Modernization planning
- Code transformation
- Dependency analysis
- Testing
- Documentation

---

**Lab:** IBM Bob Java Modernization  
**Application:** ModResorts  
**Starting Runtime:** Java 8 / Traditional WebSphere
