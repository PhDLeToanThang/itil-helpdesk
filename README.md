# ITIL - Helpdesk:
 IT SAM - IT Asset - ITIL - Helpdesk - Ticket - KB - Troubleshoot - Proposale Internal IT Lead ISO vs Audit

**Introduction ITL -Helpdesk:**
![image](https://user-images.githubusercontent.com/106635733/200482934-b52a3b25-85cb-4b18-8db8-ea6e4d01b28a.png)



**IV. ITIL Incident Management:**

**- What is Incident Management:**

An incident is an event that may result in the loss or disruption of an organization’s operations, services or functions. Incident management (ICM) is a term that describes an organization’s activities to identify, analyze, and remediate hazards to prevent them from occurring again in the future.

These events within a structured organization are normally handled by an incident response team (IRT), an incident management team (IMT), or the Incident Command System (ICS). Without effective incident management, an incident can disrupt business operations, information security, IT systems, employees, customers, or other vital business functions.

Without incident management, you could lose valuable data, gain low productivity and revenue due to downtime, or be held liable for breaches of service level agreements (SLAs). Even when incidents are insignificant and cause no lasting damage, IT teams should devote valuable time to investigating and fixing problems.
![image](https://user-images.githubusercontent.com/106635733/200489222-2d76ab55-a91a-490e-aa34-0b72cee77830.png)

Some of the most important benefits of implementing an incident management strategy include:
 1. Prevention of incidents
 2. Improved mean time to resolution (MTTR)
 3. Reducing or eliminating downtime
 4. Higher data accuracy
 5.Improved customer experience

Another benefit of incident management applications is an overall reduction in costs. According to a study by Gartner, system or service downtime can cost organizations up to $ 300,000 per hour. Additionally, legal fines and loss of customer trust can have significant financial implications. With incident management, organizations may have to invest upfront, but avoid significant costs later on.

**- The classic incident management activities as outlined in ITIL 4 are:**

![image](https://user-images.githubusercontent.com/106635733/200486582-c14f6fe6-e378-470a-86cf-848139648bc5.png)

Successful incident management relies on having a clear understanding of what the customer agreed to or is willing to tolerate regarding the duration and handling of any particular incident. This is usually defined in service level agreements (SLAs) or contracts, which include timelines for responding and resolving incidents based on some criteria, usually priority, as a function of impact and urgency.

**- 7 Steps to Automate Incident Management Processes:**

![image](https://user-images.githubusercontent.com/106635733/200484346-cc2417ed-b6ea-408f-8411-847d89c6f7d8.png)

**- Create an Incident Management Workflow (AKA An Incident Life Cycle):**

![image](https://user-images.githubusercontent.com/106635733/200484508-4d9d38d6-269f-4b55-86d1-2aedaf02b891.png)

**- Standardize Root Cause Analysis (RCA) and Prioritization:**

![image](https://user-images.githubusercontent.com/106635733/200484659-d5c24dfe-bf97-42b2-9cde-858eec941f37.png)

**- Operational incident management requires several key pieces:**

![image](https://user-images.githubusercontent.com/106635733/200485116-3fece66d-d694-4258-b22d-1a70d5667538.png)

A service desk is divided into tiers of support: L1, L2, L3, etc.

**L1:**
The first tier is for basic issues, such as password resets and basic computer troubleshooting. Tier-one incidents are most likely to turn into incident models, since the templates to create them are easy and the incidents recur often. For example, a template model for a password reset includes:
    The categorization of the incident (category of “Account” and type “Password Reset”, for example)
    A template of information that the support staff completes (username and verification requirements, in this case)
    Links to internal or external knowledge base articles that support the incident.
Low-priority tier-one incidents do not impact the business in any way and can be worked around by users.

**L2:**
Second-tier support involves issues that need more skill, training, or access to complete. Resetting an RSA token, for example, may require tier-two escalation. Some organizations categorize incidents reported by VIPs as tier two to provide a higher quality of service to those employees. Tier-two incidents may be medium-priority issues, which need a faster response from the service desk.

**L3:**
Correct assignment of tiers and priorities occurs when most incidents fall into tier one/low priority, some fall into tier two, and few require escalation to tier three. Those that require urgent escalation become major Incidents, which require the “all hands on deck” response.
Major incidents are defined by ITIL as incidents that represent significant disruption to the business. These are always high priority and warrant immediate response by the service desk and often escalation staff. In the tiered support structure, these incidents are tier three and are good candidates for problem management.

**- The incident process:**

![image](https://user-images.githubusercontent.com/106635733/200485201-72fbface-bfae-4765-8f25-44c9a29b196b.png)

**-Incident response:**

![image](https://user-images.githubusercontent.com/106635733/200485335-10e8f5c4-b809-4107-8dc8-0ebc179ff3af.png)

**6 Goals of Incident Management:**
The prime goal of incident management is to resolve incidents either with temp fix or perm fix and bring back the IT service. We list here a few steps involved during the incident process.

![image](https://user-images.githubusercontent.com/106635733/200489784-54141cb9-0700-47d5-b530-459e91d2cfb5.png)

1.Resolve incidents to reduce downtime to the business
The prime goal of incident management is to resolve incidents either with temp fix or perm fix and bring back the IT service. Resolving the incidents firstly requires registering the incident in the ITSM tool with a unique reference number. Categorization of the incident is done based on hardware, software, etc., and then the incident is assigned to the appropriate team or a person to take quick action. The investigation and diagnosis are made. The resolution is implemented by searching knowledge articles or reference materials or KEDB, and once the issue is resolved, the incident is closed.

2.Improve the quality of IT service and increase the availability of the operation of the service:
Incident management can improve the quality of IT services by identifying the recurring incidents and logging problem tickets to identify the root cause of the incident/ incidents. If there is any recent incident with no resolution, then a problem ticket is created to identify the root cause and fix it.
By identifying the recurring incidents and their associated CI’s, availability management or capacity management or information security management, or continuity management can redefine or revise the respective plans and procedures to improve the delivery of services.

3.Monitoring of services, detecting and mitigating incidents:
As the incident management team in many organizations is also involved in monitoring, they will get a complete picture of why the incident occurred, what errors or warnings, or exceptions have occurred. Accordingly, the monitoring team can consolidate the complete information from monitoring and event management tools and inform the problem management team for quicker resolution of unknown incidents. 

4.Communicate regarding the progress of the major incidents to all stakeholders
The incident management team will communicate the major incidents' progress to the necessary stakeholders from the moment it has been registered to the closure.
The incident management team keeps sending notifications regularly after every half an hour or the defined timelines to all the relevant stakeholder giving information on the incident like:
 1. What is the incident?
 2. What is the priority?
 3. When the incident occurred?
 4. Where is the incident happening or happened?
 5. What is the associated CI?
 6. How many people are impacted?
 7. Who is working on the issue?
 8. Estimated time to resolve the incident

5.Ensure SLA’s don’t breach for any reason:
The incident manager and management team will have to ensure the SLA doesn’t breach any of the incident tickets for any reason like 3rd party involvement, negligence of the incident management team, dependency on any other problem, or change ticket.

6.Measure the effectiveness of incident management operations:
The incident manager has to track the effectiveness of the incident management operations by defining the metrics and KPI’s (Key Performance Indicators) like:
 1. Number of incidents
 2. Number of major incidents
 3. Number of recurring incidents
 4. The average time is taken to resolve the incident
 5. The average time is taken to resolve the major incident
 6. Incidents that triggered problem tickets
 7. Incidents that began change tickets

