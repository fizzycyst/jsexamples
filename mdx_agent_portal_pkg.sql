set scan off
-- 
create or replace package mdx_agent_portal_pkg as
/******************************************************************************/
/* Created by:      Andrea McMillan                                           */
/* Created when:    10-OCT-2016                                               */
/* Description:     Package to hold the Agent Portal Manage my applications   */
/*                  Note this is cloned from the bwskalog.P_DispChoices but   */
/*                  modified to run from the Agent login and then pass over   */
/*                  to the individual applicant - either aidm (incomplete or  */
/*                  not yet pushed applications) or pidm (pushed applications)*/
/******************************************************************************/
/* Modified by:     Jeff Pearce                                               */
/* Modified when    12-OCT-2016                                               */
/* Description:     Altered code to speed the return of applicant listing.    */
/*                  Altered mdx_agent_allow_f removing the need for a union   */
/*                  in the driving sql.                                       */
/*                  Added new cursor in mdx_agent_applicant_detail_p          */
/*                  get_details_exist , this is to replace                    */
/*                  cursr get_details_check_c.                                */  
/******************************************************************************/
/* Modified by:     Andrea McMillan                                           */
/* Modified when    27-OCT-2016                                               */
/* Description:     Altered mdx_agent_applicant_list_p to fix an issue of the */
/*                  p_offer parameter not getting correctly passed to the     */
/*                  detail page.  Moved the call to get_decision_details_c to */
/*                  earlier in the procedure and moved the formhidden pass    */
/*                  to the p_offer to where the Student ID button is          */
/*                  changes annotated   -- 27-OCT-2016                        */
/******************************************************************************/
/* Modified by:     Andrea McMillan                                           */
/* Modified when    07-NOV-2016                                               */
/* Description:     Altered the code to only make usuable links to the        */
/*                  applicant portal for Document Upload/Submit further info  */
/*                  and Professional checks if they have a sabnstu or         */
/*                  mdx_sabnstu record.  Conditions of offer are currently    */
/*                  not a clickable links but the same change will be applied */
/*                  to this functionality once Offer Letters are available via*/
/*                  the portal. Plus fixed a bug in the Applicant Detail page */
/*                  get_details_c cursor where finding if the                 */
/*                  display_fee_section the added distinct 'Y'                */
/*                  Changes annotated                                         */
/*                  -- ADM 07-NOV-2016 start                                  */
/*                  -- ADM 07-NOV-2016 end                                    */
/******************************************************************************/
/* Modified by:     Andrea McMillan                                           */
/* Modified when    09-NOV-2016                                               */
/* Description:     mdx_agent_applicant_detail_p changed the address cursor   */
/*                  to remove the spraddr_natn_code as we do not hold the     */
/*                  applicants country for overseas addresses in this field.  */
/*                  MISIS Core FAQ indicates that the country is held in the  */
/*                  city field for overseas addresses.  Also added a nvl to   */
/*                  all the address fields to not display if the field only   */
/*                  contains a full-stop.                                     */
/*                  Changes annotated                                         */
/*                  -- ADM 09-NOV-2016                                        */
/******************************************************************************/
/* Modified by:     Jeff Pearce                                               */
/* Modified when    03-Feb-2017                                               */
/* Description:     Made numerous alterations to both mdx_agent_allow_f and   */
/*                  mdx_agent_applicant_list_p to allow agents grouped via    */
/*                  SKVSSDT to see all applicants they are entitled to view.  */
/*                  Alterations are identified by:                            */
/*                  -- jmp jan 2017 start                                     */
/*                  -- jmp jan 2017 end                                       */ 
/******************************************************************************/
/* Modified by:     Andrea McMillan                                           */
/* Modified when    28-MAR-2017                                               */
/* Description:     Made changes to the mdx_agent_applicant_list_p to duplicate the */
/*                  functionality of viewing the offer letter as in bwskalog. */
/*                  P_DispChoices procedure.  Note it uses the same Offer     */
/*                  letter page as bwskalog.mdx_applicant_offer_p with the    */
/*                  response buttons hidden from Agents                       */
/*                  Also added a View offer letter button in the              */
/*                  mdx_agent_applicant_detail_f if an offer letter exists    */
/*                  and the pdf has filename is not null                      */
/*                  Also added the new link to TWARPAY tables via the appno   */
/*                  and also now shows the deposit payment for UA, C, CF and  */
/*                  also allow APPL comments to be displayed                  */
/*                  Made a change to how we display the offer string on the   */
/*                  mdx_agent_applicant_detail_p page to bring it into line   */
/*                  the offer letters                                         */
/*                  Fixed a bug in mdx_agent_applicant_list_p where the NOA   */
/*                  in the get_details_c cursor where the aidm was set as null*/
/*                  but needed to check the sabiden table for if an aidm      */
/*                  existed for the scenario of if originall an online app    */
/*                  but a later DA app added to their record their login      */
/*                  credentials are in the sabnstu table and not the mdx one  */
/*                  Changes annotated                                         */
/*                  -- ADM Nov 2016 Offer Letter changes - START              */
/*                  -- ADM Nov 2016 Offer Letter changes - END                */
/******************************************************************************/
/* Modified by:     Andrea McMillan                                           */
/* Modified when    07-AUG-2017                                               */
/* Description:     Made changes to mdx_agent_applicant_list_p to hide any    */
/*                  UCAS (skrsain_source = 'U') as it loops through the       */
/*                  get_details_c cursor if the embargo period is active      */
/*                  Changes annotated                                         */
/*                  -- ADM AUG 2017 START                                     */
/*                  -- ADM AUG 2017 END                                       */
/******************************************************************************/
/* Modified by:     Paul Gilfedder                                            */
/* Modified when    14-NOV-2017                                               */
/* Description:     Made changes to mdx_agent_applicant_list_p to allow       */
/*                  filtering the list on column content                      */
/*                  using javascript to add search fields and drop downs      */
/*                  searches are free text.                                   */
/*                  Changes annotated                                         */
/*                  -- PG NOV 2017 START                                     */
/*                  -- PG NOV 2017 END                                       */
/******************************************************************************/
    FUNCTION mdx_agent_allow_f(p_aidm                    number default null
                               ,p_pidm                    number default null
                               ,p_skrsain_rowid           rowid
                               ,p_sarhead_appl_seqno      varchar2
                               ,p_sarhead_term_code_entry varchar2
                               ,p_agency_code             varchar2 
                               ,p_agent_id                varchar2
                               ,p_view                    varchar2 -- ALL, OWN, GROUP
                               ,p_group_a                 varchar2 default null
                               ,p_group_b                 varchar2 default null
                               ,p_group_c                 varchar2 default null                                            
                               ,p_group_d                 varchar2 default null)
                                             
   RETURN varchar2;
      
   PROCEDURE mdx_agent_applicant_list_p (p_agent_id varchar2 default null);-- this is the email address
   
   PROCEDURE mdx_agent_applicant_detail_p (p_xceduz              varchar2 -- note this is just a security param to make hacking page harder
                                          ,p_pidm                number   default null
                                          ,p_aidm                number   default null
                                          ,p_appno               number   default null
                                          ,p_term_code_entry     varchar2  default null
                                          ,p_skrsain_source      varchar2 default null
                                          ,p_skrsain_applicant_no varchar2 default null
                                          ,p_app_type            varchar2 default null
                                          ,p_offer               number default null
                                          ,in_id                 varchar2 default null
                                          ,pin                   varchar2 default null
                                          ,msg                   varchar2 default null   
                                          ,p_agent_id            varchar2  default null
                                          ,p_comment             varchar2 default null);
                                          
   -- this procedure params should always mimic the mdx_agent_applicant_detail_p
   -- this procedure will log the agent into the individual applicants account prior
   -- to opening the detail page so when a link to an individual applicant page is selected it will
   -- open without any problems
   PROCEDURE mdx_agent_portal_piggyback_p (p_xceduz              varchar2 -- note this is just a security param to make hacking page harder
                                          ,p_pidm                number   default null
                                          ,p_aidm                number   default null
                                          ,p_appno               number   default null
                                          ,p_term_code_entry     varchar2  default null
                                          ,p_skrsain_source      varchar2 default null
                                          ,p_skrsain_applicant_no varchar2 default null
                                          ,p_app_type            varchar2 default null
                                          ,p_offer               number default null);

   PROCEDURE mdx_agent_applicant_process_p (p_xceduz             varchar2 -- note this is just a security param to make hacking page harder
                                          ,p_pidm                number    default null
                                          ,p_aidm                number    default null
                                          ,p_appno               number    default null
                                          ,p_term_code_entry     varchar2  default null
                                          ,p_skrsain_source      varchar2  default null
                                          ,p_skrsain_applicant_no varchar2 default null
                                          ,p_app_type            varchar2  default null
                                          ,p_offer               number    default null
                                          ,submit_btn            varchar2  default null
                                          ,p_comment             varchar2  default null
                                          ,p_agency              varchar2  default null
                                          ,p_agent_id            varchar2  default null
                                          ,PAGE_ROUTE            varchar2  default null
                                          ,submit_btn2           varchar2  default null
                                          ,in_id                 varchar2 default null
                                          ,pin                   varchar2 default null);

end    mdx_agent_portal_pkg;
/
--------------------------------------------------------------------------------
create or replace PACKAGE BODY mdx_agent_portal_pkg AS
/******************************************************************************/
/* Created by:      Andrea McMillan                                           */
/* Created when:    21-JUN-2016                                               */
/* Description:     Package to hold the Agent Portal Manage my applications   */
/*                  Note this is cloned from the bwskalog.P_DispChoices but   */
/*                  modified to run from the Agent login and then pass over   */
/*                  to the individual applicant - either aidm (incomplete or  */
/*                  not yet pushed applications) or pidm (pushed applications)*/
/******************************************************************************/
-- set up any global variables
  submit_btn  varchar2(20);
  submit_btn2 varchar2(20);  
-------------------------------------------------------------------------------
FUNCTION mdx_agent_allow_f(p_aidm                    number default null
                          ,p_pidm                    number default null
                          ,p_skrsain_rowid           rowid
                          ,p_sarhead_appl_seqno      varchar2
                          ,p_sarhead_term_code_entry varchar2
                          ,p_agency_code             varchar2 
                          ,p_agent_id                varchar2
                          ,p_view                    varchar2 -- ALL, OWN, GROUP
                          ,p_group_a                 varchar2 default null
                          ,p_group_b                 varchar2 default null
                          ,p_group_c                 varchar2 default null                                            
                          ,p_group_d                 varchar2 default null)
                                             
RETURN varchar2 as
  
l_result char(1) default 'N'; 

l_group_a varchar2(1);
l_group_b varchar2(1);
l_group_c varchar2(1);
l_group_d varchar2(1);
 
  -- where no skrsain record is passed in then get the values from the sarrqst questions
 
  cursor get_details_c is
select 'Y'
from dual
where 1=1
and exists
( select 'Y'
  from skrsain
  where 1 = 1
  and   rowid                   = p_skrsain_rowid
  and   p_view                  = 'ALL'
--jmp jan 2017 start
--  and   skrsain_ssdt_code_inst3 in (p_agency_code))
  and instr(p_agency_code,skrsain_ssdt_code_inst3) > 0)
--jmp jan 2017 end
or exists 
(  select 'Y'
  from  sarrqst
  where 1=1
  and   sarrqst_wudq_no         = 201
  and   sarrqst_aidm            = p_aidm
  and   sarrqst_appl_seqno      = p_sarhead_appl_seqno
  and   p_skrsain_rowid         is null
  and   p_view                  = 'ALL'
--jmp jan 2017 start
--  and   trim(SARRQST_ANSR_DESC) in (p_agency_code))
  and instr(p_agency_code,trim(SARRQST_ANSR_DESC)) > 0)
--jmp jan 2017 end
or exists 
(  select 'Y'
  from skrsain
  where 1 = 1
  and   skrsain_ssdt_code_inst4  =  p_agent_id
  and   rowid                    = p_skrsain_rowid
  and   p_view                   = 'OWN'
--jmp jan 2017 start
--  and   skrsain_ssdt_code_inst3 in (p_agency_code))
  and instr(p_agency_code,skrsain_ssdt_code_inst3) > 0)
--jmp jan 2017 end
or exists
(  select 'Y'
  from   sarrqst b
        ,sarrqst a
  where 1 = 1
  and   trim(b.SARRQST_ANSR_DESC) = p_agent_id
  and   b.sarrqst_wudq_no         = 202
  and   b.sarrqst_aidm            = p_aidm
  and   b.sarrqst_appl_seqno      = p_sarhead_appl_seqno
--jmp jan 2017 start
--  and   trim(a.SARRQST_ANSR_DESC) in (p_agency_code)
  and instr(p_agency_code,trim(a.SARRQST_ANSR_DESC)) > 0
--jmp jan 2017 end
  and   a.sarrqst_wudq_no         = 201
  and   a.sarrqst_aidm            = p_aidm
  and   a.sarrqst_appl_seqno      = p_sarhead_appl_seqno
  and   p_skrsain_rowid         is null
  and   p_view                  = 'OWN')
;
/*
  select 'Y'
  from skrsain
  where 1 = 1
  and   skrsain_ssdt_code_inst3 in (p_agency_code)
  and   rowid                   = p_skrsain_rowid
  and   p_view                  = 'ALL'
  union
  select 'Y'
  from  sarrqst
  where trim(SARRQST_ANSR_DESC) in (p_agency_code)
  and   sarrqst_wudq_no         = 201
  and   sarrqst_aidm            = p_aidm
  and   sarrqst_appl_seqno      = p_sarhead_appl_seqno
  and   p_skrsain_rowid         is null
  and   p_view                  = 'ALL'
  union
  select 'Y'
  from skrsain
  where 1 = 1 
  and   skrsain_ssdt_code_inst4  =  p_agent_id
  and   skrsain_ssdt_code_inst3 in (p_agency_code)
  and   rowid                    = p_skrsain_rowid
  and   p_view                   = 'OWN'
  union
  select 'Y'
  from   sarrqst b
        ,sarrqst a
  where 1 = 1
  and   trim(b.SARRQST_ANSR_DESC) = p_agent_id
  and   b.sarrqst_wudq_no         = 202
  and   b.sarrqst_aidm            = p_aidm
  and   b.sarrqst_appl_seqno      = p_sarhead_appl_seqno
  and   trim(a.SARRQST_ANSR_DESC) in (p_agency_code)
  and   a.sarrqst_wudq_no         = 201
  and   a.sarrqst_aidm            = p_aidm
  and   a.sarrqst_appl_seqno      = p_sarhead_appl_seqno
  and   p_skrsain_rowid         is null
  and   p_view                  = 'OWN';
*/

cursor check_group_c is
  select nvl(MDX_AGENT_CONTACTS_GROUP_A,'N')      agent_group_a
         ,nvl(MDX_AGENT_CONTACTS_GROUP_B,'N')      agent_group_b      
         ,nvl(MDX_AGENT_CONTACTS_GROUP_C,'N')      agent_group_c   
         ,nvl(MDX_AGENT_CONTACTS_GROUP_D,'N')      agent_group_d
  from mdx_agent_contacts 
       ,skrsain  sk
  where 1 = 1
  and   nvl(MDX_AGENT_CONTACTS_VIEW_GROUP,'N') = 'Y'
--jmp jan 2017 start
--  and   mdx_agent_contacts_agent_code in (p_agency_code)
  and instr(p_agency_code,mdx_agent_contacts_agent_code) > 0
--jmp jan 2017 end
  and   mdx_agent_contacts_id    = skrsain_ssdt_code_inst4
--jmp jan 2017 start
--  and   skrsain_ssdt_code_inst3 in (p_agency_code)
  and instr(p_agency_code,trim(skrsain_ssdt_code_inst3)) > 0
--jmp jan 2017 end
  and   sk.rowid                    = p_skrsain_rowid
  and   p_view                   = 'GROUP'
  UNION
  select nvl(MDX_AGENT_CONTACTS_GROUP_A,'N')      agent_group_a
         ,nvl(MDX_AGENT_CONTACTS_GROUP_B,'N')      agent_group_b      
         ,nvl(MDX_AGENT_CONTACTS_GROUP_C,'N')      agent_group_c   
         ,nvl(MDX_AGENT_CONTACTS_GROUP_D,'N')      agent_group_d
  from mdx_agent_contacts 
       ,sarrqst b
       ,sarrqst a
  where 1 = 1
  and   nvl(MDX_AGENT_CONTACTS_VIEW_GROUP,'N') = 'Y'
--jmp jan 2017 start
--  and   mdx_agent_contacts_agent_code in (p_agency_code)
  and instr(p_agency_code,mdx_agent_contacts_agent_code) > 0
--jmp jan 2017 end
  and   mdx_agent_contacts_id    = trim(b.SARRQST_ANSR_DESC)
  and   b.sarrqst_wudq_no         = 202
  and   b.sarrqst_aidm            = p_aidm
  and   b.sarrqst_appl_seqno      = p_sarhead_appl_seqno
  and   trim(a.SARRQST_ANSR_DESC) in (p_agency_code)
  and   a.sarrqst_wudq_no         = 201
  and   a.sarrqst_aidm            = p_aidm
  and   a.sarrqst_appl_seqno      = p_sarhead_appl_seqno
  and   p_skrsain_rowid         is null
  and   p_view                   = 'GROUP'; 
  
BEGIN

   if p_view in ('ALL','OWN') then
   
     open get_details_c;
     fetch get_details_c into l_result;
     close get_details_c;
   
   elsif p_view = 'GROUP'
     then
 
     open check_group_c;
     fetch check_group_c into l_group_a
                             ,l_group_b
                             ,l_group_c
                             ,l_group_d;
     close check_group_c;
--
        if (l_group_a = 'Y' and p_group_a = 'Y')
          then
             l_result := 'Y';
        end if;
        
        if (l_group_b = 'Y' and p_group_b = 'Y')
          then
             l_result := 'Y';
        end if;
        
        if (l_group_c = 'Y' and p_group_c = 'Y')
          then
             l_result := 'Y';        
        end if;
        
        if (l_group_d = 'Y' and p_group_d = 'Y')
          then
             l_result := 'Y';     
        end if;
 
   end if;       
           
   return nvl(l_result,'N');

END mdx_agent_allow_f;


-------------------------------------------------------------------------------
   PROCEDURE mdx_agent_applicant_list_p (p_agent_id varchar2) --(xpidm     in number)--(appno NUMBER)--(in_secured VARCHAR2 DEFAULT NULL)
   IS
    --  app_rec          app_type;
   back_url          VARCHAR2 (255);
   dflt_back_link    VARCHAR2 (255);
  app_exit_url   VARCHAR2 (60) := 'mdx_agent_pkg.mdx_landing_p';--'MDX_APPLICANT_LANDING_PAGE_PKG.p_displayPage'; --'bwskalog.p_displogoutnon';
 
  l_curr_release   CONSTANT VARCHAR2 (10)             := '8.5.4';
  cell_msg_flag    VARCHAR2 (1);
  display_msg      varchar2(2000); 
 
      
      aidm             NUMBER;
      pidm             spriden.spriden_pidm%type;


      sarhead_rec      sarhead%ROWTYPE;
      saradap_rec      saradap%ROWTYPE;
      stvwsct_rec      stvwsct%ROWTYPE;
      wapp_wsct_desc   VARCHAR2 (60);
      preference_usage BOOLEAN:=FALSE;
      program_desc     sorcmjr.sorcmjr_desc%TYPE;
      curr_rule        sorcmjr.sorcmjr_curr_rule%TYPE;
      sec_men          VARCHAR2(1) := NULL;

-- mdx adm start Oct 2015
      l_pidm_c                  spriden.spriden_pidm%type; -- this one is found my my cursor get_pidm_c which does additonal checking in mdx_sabnstu to get the pidm

      l_pidm                    spriden.spriden_pidm%type;
      l_appno                   sarhead.sarhead_appl_seqno%type;
      l_term_code_entry         stvterm.stvterm_code%type;
      l_sarhead_appl_comp_ind   sarhead.sarhead_appl_comp_ind%type;
      l_sarhead_process_ind     sarhead.sarhead_process_ind%type;
      l_sarhead_wapp_code       sarhead.sarhead_wapp_code%type;
      l_application_type        varchar2(10); -- OA online application, NOA non online application
      l_query                   varchar2(10);
      l_program                 sobcurr.sobcurr_program%type;
      l_prog_desc               mdx_prog.mdx_prog_long_title%type;
      l_term_desc               stvterm.stvterm_desc%type;
      l_status                  varchar2(200);
      l_app_created             date;
      l_my_actions              varchar2(2000);
      l_decision_code           sarappd.sarappd_apdc_code%type;
      l_decision_date           date;
      l_UF_Decision             char(1) default 'N'; -- Y/N                       
      l_C_Decision              sarappd.sarappd_apdc_code%type default '~';
      l_offer_text              skrudec.skrudec_off_lib_string%type; 
      l_offer                   skrudec.skrudec_decn_seq%type;--rowid;
      l_skrsain_source          skrsain.skrsain_source%type;
--
      l_embargo_active          char(1) default 'N';    
      l_embargo_start_date      date;
      l_embargo_start_time      gtvsdax.GTVSDAX_TRANSLATION_CODE%type;      
      l_embargo_org_start_date  date;
      l_embargo_end_date        date;
      l_embargo_org_end_date    date;
      l_embargo_end_time        gtvsdax.GTVSDAX_TRANSLATION_CODE%type;  
-- mdx AM end July 2016

      l_saradap_admt_code       saradap.saradap_admt_code%type;
      l_last_updated            date;
      l_professional_checks     char(1) default 'N';
      l_display_prof_check_link char(1) default 'N';
--
      l_sabnstu_web_last_access        date;
      l_sabnstu_last_login_date        date;
      l_mdx_sabnstu_web_last_access    date;
      l_mdx_sabnstu_last_login_date    date;
--
-- Agent Variables - these are their primary agency login details
      l_view                varchar2(5) default null;
      l_agency_name         skvssdt.skvssdt_title%type;
      l_agency_code         mdx_agent_contacts.mdx_agent_contacts_agent_code%type;
      l_agent_id            mdx_agent_contacts.MDX_AGENT_CONTACTS_id%type;
      l_agent_seq            mdx_agent_contacts.MDX_AGENT_CONTACTS_SEQ%type;
      l_agent_type          mdx_agent_contacts.MDX_AGENT_CONTACTS_TYPE%type;
      l_agent_name          mdx_agent_contacts.MDX_AGENT_CONTACTS_NAME%type;
      l_agent_view_all      char(1) default 'N';
      l_agent_view_group    char(1) default 'N';
      l_agent_view_own      char(1) default 'N';
      l_agent_group_a       char(1) default 'N';
      l_agent_group_b       char(1) default 'N';
      l_agent_group_c       char(1) default 'N';
      l_agent_group_d       char(1) default 'N';
      l_agent_active_ind    mdx_agent_contacts.MDX_AGENT_CONTACTS_ACTIVE%type default 'N';
      l_agency_codes_all    varchar2(200) default null;
      l_groups              varchar2(5) default null;
      l_agency_code_sec     mdx_agent_contacts.mdx_agent_contacts_agent_code%type;
      l_regional_office_code MDX_AGENT_REG_OFF.MDX_AGENT_REG_OFF_code%type;
      l_student_id          varchar2(200); -- this can be an MDX number or an email address for incomplete apps where no record has been pushed yet --spriden.spriden_id%type;
      l_last_name           spriden.spriden_last_name%type;
      l_first_name          spriden.spriden_first_name%type;
      l_middle_name         spriden.spriden_mi%type;
      l_birth_date          date;
      l_name_prefix         spbpers.spbpers_name_prefix%type;
      l_resd_desc           skvssdt.skvssdt_short_title%type;
      l_aidm                sarhead.sarhead_aidm%type;
      l_skrsain_applicant_no skrsain.skrsain_applicant_no%type;
      l_applicant_agent_name  mdx_agent_contacts.MDX_AGENT_CONTACTS_NAME%type;
--
   l_webid    mdx_sabnstu.mdx_sabnstu_id%type;
   l_web_pin  mdx_sabnstu.mdx_sabnstu_pin%type;
   l_login_url  varchar2(500);
--
-- ADM Nov 2016 Offer Letter changes - START
      l_offer_letter_exists char(1) default 'N';
-- ADM Nov 2016 Offer Letter changes - END
--
   --
   cursor get_login_details_c is
   SELECT mdx_sabnstu_id
         ,mdx_sabnstu_pin
   FROM mdx_sabnstu
   WHERE mdx_sabnstu_pidm = l_pidm
   union
   select sabnstu_id
         ,sabnstu_pin
   from sabnstu
   where sabnstu_aidm = l_aidm;
--
cursor get_pidm_c (aidm NUMBER)
IS
/*SELECT sabiden_pidm
FROM sabiden
WHERE sabiden_aidm = aidm
union -- top union not required as we have already used the Ellucian cursor to check this table*/
SELECT mdx_sabnstu_pidm
FROM mdx_sabnstu
WHERE mdx_sabnstu_aidm = aidm
union
select mdx_sabnstu_pidm
from mdx_sabnstu
    ,sabnstu
where 1 = 1
and lower(mdx_sabnstu_id) = lower(sabnstu_id)
and sabnstu_aidm = aidm;

--
cursor get_ucas_embargo_dates_c is
-- mdx AM start July 2016
-- added a time element to the Embargo dates that
-- means we now hold the details in two GTVSDAX entries
/*select GTVSDAX_REPORTING_DATE     embargo_start_date
      ,gtvsdax_translation_code   embargo_end_date
from gtvsdax
where  gtvsdax_internal_code       = 'UCASEMBARG'
and    gtvsdax_internal_code_group = 'APPLICANTSELFSERVICE';*/
select (select GTVSDAX_REPORTING_DATE     
            --  ,gtvsdax_translation_code   embargo_end_date
        from gtvsdax
        where  gtvsdax_external_code       = 'START'
        and    gtvsdax_internal_code       = 'UCASEMBARG'
        and    gtvsdax_internal_code_group = 'MDX_APPL_SS') embargo_start_date
      ,(select gtvsdax_translation_code     
        from gtvsdax
        where  gtvsdax_external_code       = 'START'
        and    gtvsdax_internal_code       = 'UCASEMBARG'
        and    gtvsdax_internal_code_group = 'MDX_APPL_SS') embargo_start_time       
       ,(select GTVSDAX_REPORTING_DATE     
            --  ,gtvsdax_translation_code   embargo_end_date
        from gtvsdax
        where  gtvsdax_external_code       = 'END'
        and    gtvsdax_internal_code       = 'UCASEMBARG'
        and    gtvsdax_internal_code_group = 'MDX_APPL_SS') embargo_end_date
      ,(select gtvsdax_translation_code     
        from gtvsdax
        where  gtvsdax_external_code       = 'END'
        and    gtvsdax_internal_code       = 'UCASEMBARG'
        and    gtvsdax_internal_code_group = 'MDX_APPL_SS') embargo_end_time 
from dual;
-- mdx AM start July 2016

/* this is the Ellucian way of identifying what terms to display
    however we have swapped over to using the RECRUIT_TERM in skassdt
AND (stvwapp_code        IN 
  (SELECT sarwatd_wapp_code
  FROM sarwatd
  WHERE sarwatd_term_code = sarhead_term_code_entry
  AND sarwatd_wapp_code   = stvwapp_code
  AND TO_CHAR(sysdate) BETWEEN sarwatd_start_date AND sarwatd_end_date
  )
OR (stvwapp_code NOT IN
  (SELECT sarwatd_wapp_code FROM sarwatd WHERE sarwatd_wapp_code = stvwapp_code
  )
AND sarhead_term_code_entry IN
  (SELECT soratrm_term_code
  FROM soratrm
  WHERE TO_CHAR(sysdate) BETWEEN soratrm_start_date AND soratrm_end_date
  ) ) )*/

cursor get_agent_details_c is
select skvssdt_title                   agency_name
      ,mdx_agent_contacts_agent_code   agency_code
      ,MDX_AGENT_CONTACTS_SEQ          agent_seq
      ,mdx_agent_contacts_id           agent_id
      ,MDX_AGENT_CONTACTS_TYPE         agent_type
      ,MDX_AGENT_CONTACTS_NAME         agent_name
      ,nvl(MDX_AGENT_CONTACTS_VIEW_ALL,'N')     agent_view_all
      ,nvl(MDX_AGENT_CONTACTS_VIEW_GROUP,'N')   agent_view_group
      ,nvl(MDX_AGENT_CONTACTS_VIEW_OWN,'N')     agent_view_own
      ,nvl(MDX_AGENT_CONTACTS_GROUP_A,'N')      agent_group_a
      ,nvl(MDX_AGENT_CONTACTS_GROUP_B,'N')      agent_group_b      
      ,nvl(MDX_AGENT_CONTACTS_GROUP_C,'N')      agent_group_c   
      ,nvl(MDX_AGENT_CONTACTS_GROUP_D,'N')      agent_group_d
      ,MDX_AGENT_CONTACTS_ACTIVE       agent_active_ind
      ,(select MDX_AGENT_REG_OFF_code
        from MDX_AGENT_REG_OFF
        where MDX_AGENT_REG_OFF_agent_code = mdx_agent_contacts_agent_code) regional_office
FROM  skvssdt
      ,mdx_agent_contacts 
where 1 = 1
and  nvl(SKVSSDT_STATUS_IND,'I') = 'A'
and  SKVSSDT_SDAT_CODE_OPT_1     =  mdx_agent_contacts_agent_code
--and  MDX_AGENT_CONTACTS_EMAIL       = p_agent_id;  
and  lower(MDX_AGENT_CONTACTS_EMAIL)       = lower(p_agent_id);  
--and  MDX_AGENT_CONTACTS_SEQ      = p_agent_id; --'AGT0001_C5bm';  -- CHANGE OVER TO PROPER LOGIN

cursor get_agent_secondary_details_c is
select SKVSSDT_SDAT_CODE_OPT_1
from   skvssdt
where  nvl(SKVSSDT_STATUS_IND,'I') = 'A'
and    SKVSSDT_DATA                = l_agency_code
and    SKVSSDT_SDAT_CODE_ATTR      = 'AGENCY'
and    SKVSSDT_SDAT_CODE_ENTITY    = 'AGENT';

                              
cursor get_details_c is
-- submitted but not processed
SELECT  null --sabiden_pidm              PIDM
      ,sarhead_appl_seqno        APPO
      ,sarhead_term_code_entry   TERM_CODE_ENTRY
      ,sarhead_appl_comp_ind   
      ,sarhead_process_ind
      ,sarhead_wapp_code          
      ,'OA'                   application_type
      ,'S'                    source_query
      ,sobcurr_program
      ,a.mdx_prog_long_title
      ,stvterm_DESC 
      ,'Submitted'   application_status
      ,sarhead_add_date        Application_created
      ,''  skrsain_source -- not yet pushed so no source
      ,'' saradap_admt_code 
      ,null last_updated 
      ,'N'  professional_checks
      ,nvl((select spriden_id
           from spriden
                ,sabiden
           where spriden_change_ind is null
           and   spriden_pidm = sabiden_pidm
           and   sabiden_aidm = sarhead_aidm),(select sabnstu_id
                                               from SABNSTU
                                               where sabnstu_aidm = sarhead_aidm)) student_id
      ,nvl((select spriden_last_name
           from spriden
                ,sabiden
           where spriden_change_ind is null
           and   spriden_pidm = sabiden_pidm
           and   sabiden_aidm = sarhead_aidm),(select sarpers_last_name
                                               from sarpers
                                               where 1 = 1
                                               and  sarpers_appl_seqno    = sarhead_appl_seqno
                                               and  sarpers_aidm          = sarhead_aidm)) spriden_last_name
      ,nvl((select spriden_first_name
            from spriden
                ,sabiden
            where spriden_change_ind is null
            and   spriden_pidm = sabiden_pidm
            and   sabiden_aidm = sarhead_aidm),(select sarpers_first_name
                                                from sarpers
                                                where 1 = 1
                                                and  sarpers_appl_seqno    = sarhead_appl_seqno
                                                and  sarpers_aidm          = sarhead_aidm)) spriden_first_name      
      ,nvl((select spriden_mi
            from spriden
                 ,sabiden
            where spriden_change_ind is null
            and   spriden_pidm = sabiden_pidm
            and   sabiden_aidm = sarhead_aidm),(select sarpers_middle_name1
                                                from sarpers
                                                where 1 = 1
                                                and  not exists  (select 'Y'
                                                                  from  sabiden
                                                                  where sabiden_pidm is not null
                                                                  and   sabiden_aidm = sarpers_aidm)
                                                and  sarpers_appl_seqno    = sarhead_appl_seqno
                                                and  sarpers_aidm          = sarhead_aidm)) spriden_mi  
      ,nvl((select to_char(spbpers_birth_date,'DD-MON-YYYY')
            from spbpers
                 ,sabiden
            where 1=1
            and   spbpers_pidm = sabiden_pidm
            and   sabiden_aidm = sarhead_aidm),(select to_char(TO_DATE(sarpers_birth_dte,'MM/DD/YYYY'),'DD-MON-YYYY')
                                                from sarpers
                                                where 1 = 1
                                                and  not exists  (select 'Y'
                                                                  from  sabiden
                                                                  where sabiden_pidm is not null
                                                                  and   sabiden_aidm = sarpers_aidm)
                                                and  sarpers_appl_seqno    = sarhead_appl_seqno
                                                and  sarpers_aidm          = sarhead_aidm)) dob
      ,nvl((select spbpers_name_prefix
            from spbpers
                 ,sabiden
            where 1=1
            and   spbpers_pidm = sabiden_pidm
            and   sabiden_aidm = sarhead_aidm),(select sarpers_prefix
                                                from sarpers
                                                where 1 = 1
                                                and  not exists  (select 'Y'
                                                                  from  sabiden
                                                                  where sabiden_pidm is not null
                                                                  and   sabiden_aidm = sarpers_aidm)
                                                and  sarpers_appl_seqno    = sarhead_appl_seqno
                                                and  sarpers_aidm          = sarhead_aidm)) name_prefix
/*      ,nvl((select decode(a.skvssdt_sdat_code_opt_1 ,'000', ' United Kingdom',skvssdt_short_title )   
            from  skvssdt a
                  ,mdx_ssen_resd i
             where 1 = 1
             and  a.skvssdt_sdat_code_entity = 'HESA' 
             and  a.skvssdt_sdat_code_attr   = 'MDX_DOMICILE'
             and  a.skvssdt_status_ind       = 'A'  
             and  a.skvssdt_eff_date         <= sysdate
             and (a.skvssdt_term_date is null  or a.skvssdt_term_date  >= sysdate)
             and  SKVSSDT_SDAT_CODE_OPT_1    = i.natn_code_dom
             and  i.wsct_code         = 'RESIDENCY'
             and  i.application_no    = sarhead_appl_seqno
             and  i.aidm              = sarhead_aidm  ),'Not Supplied')  resd_desc*/
        ,sarhead_aidm
        ,null    skrsain_applicant_no
        ,(select MDX_AGENT_CONTACTS_NAME         agent_name
          from   mdx_agent_contacts 
                ,sarrqst
          where  mdx_agent_contacts_id = sarrqst_ansr_desc
          and    sarrqst_wudq_no       = 202
          and    sarrqst_appl_seqno    = sarhead_appl_seqno
          and    sarrqst_aidm          = sarhead_aidm)  applicant_agent_name
FROM --sabiden 
     mdx_prog   a
     ,sobcurr
     ,saretry
     ,stvterm
     ,sarhead
WHERE 1 = 1
and  a.mdx_prog_eff_term   = (select max(b.mdx_prog_eff_term)
                              from mdx_prog b
                              where 1 = 1
                              and   b.mdx_prog_eff_term <= sarhead_term_code_entry
                              and   b.mdx_prog_program   = a.mdx_prog_program)
and  a.mdx_prog_program    = sobcurr_program
-- jmp jan 2017 start
--and  l_agency_code          = (select trim(SARRQST_ANSR_DESC)
--                              from  sarrqst
--                              where sarrqst_wudq_no    = 201
--                              and   sarrqst_aidm       = sarhead_aidm
--                              and   sarrqst_appl_seqno = sarhead_appl_seqno) -- will need to check this works once Jeffs code is done 
-- jmp jan 2017 end
and  sobcurr_curr_rule   = SARETRY_CURR_RULE
and  saretry_appl_seqno  = sarhead_appl_seqno
and  saretry_aidm        = sarhead_aidm
and sarhead_term_code_entry in (select SKVSSDT_SHORT_TITLE
                                from skvssdt
                                where 1 = 1
                                and  skvssdt_sdat_code_entity   = 'ONLINEAP'
                                and  skvssdt_sdat_code_attr     = 'RECRUIT_TERM'
                                and  nvl(skvssdt_status_ind,'I') = 'A')
AND stvterm_code          = sarhead_term_code_entry
AND sarhead_appl_comp_ind = 'Y'
AND sarhead_process_ind  <> 'P'
and nvl(mdx_agent_portal_pkg.mdx_agent_allow_f
                        (sarhead_aidm             -- aidm
                         ,null   -- pidm
                         ,null        -- skrsain rowid
                         ,sarhead_appl_seqno           -- p_sarhead_appl_seqno
                         ,sarhead_term_code_entry   --p_sarhead_term_code_entry
-- jmp jan 2017 start
                         ,l_agency_codes_all -- jmp l_agency_code  -- p_agency_code       
-- jmp jan 2017 start
                         ,l_agent_id     -- p_agent_id                
                         ,l_view         -- ALL, OWN, GROUP
                         ,l_agent_group_a
                         ,l_agent_group_b      
                         ,l_agent_group_c   
                         ,l_agent_group_d),'N') = 'Y'   -- add in once I sort out the function
--AND sarhead_aidm          = :aidm
union all
-- incomplete
SELECT null --sabiden_pidm              PIDM
      ,sarhead_appl_seqno
      ,sarhead_term_code_entry
      ,sarhead_appl_comp_ind
      ,sarhead_process_ind
      ,sarhead_wapp_code
      ,'OA'  application_type
      ,'I'  source_query
      ,sobcurr_program
      ,a.mdx_prog_long_title
      ,stvterm_DESC 
      ,'Incomplete'   application_status
      ,sarhead_add_date        Application_created
      ,''  skrsain_source -- not yet completed so no source
      ,'' saradap_admt_code 
      ,(select to_char(max(sarwsct_activity_date),'fxDD-MON-YYYY')
        from sarwsct 
        where 1 = 1
        and sarwsct_appl_seqno = sarhead_appl_seqno 
        and sarwsct_aidm       = sarhead_aidm) last_updated
      ,'N'  professional_checks
      ,nvl((select spriden_id
           from spriden
                ,sabiden
           where spriden_change_ind is null
           and   spriden_pidm = sabiden_pidm
           and   sabiden_aidm = sarhead_aidm),(select sabnstu_id
                                               from SABNSTU
                                               where sabnstu_aidm = sarhead_aidm)) student_id
      ,nvl((select spriden_last_name
           from spriden
                ,sabiden
           where spriden_change_ind is null
           and   spriden_pidm = sabiden_pidm
           and   sabiden_aidm = sarhead_aidm),nvl((select sarpers_last_name
                                                   from sarpers
                                                   where 1 = 1
                                                   and  length(sarpers_last_name) > 1
                                                   and  sarpers_appl_seqno    = sarhead_appl_seqno
                                                   and  sarpers_aidm          = sarhead_aidm),(select last_name
                                                                                               from mdx_capture_app_reg_info
                                                                                               where aidm = sarhead_aidm))) spriden_last_name
      ,nvl((select spriden_first_name
            from spriden
                ,sabiden
            where spriden_change_ind is null
            and   spriden_pidm = sabiden_pidm
            and   sabiden_aidm = sarhead_aidm),nvl((select sarpers_first_name
                                                    from sarpers
                                                    where 1 = 1
                                                    and  length(sarpers_first_name) > 1
                                                    and  sarpers_appl_seqno    = sarhead_appl_seqno
                                                    and  sarpers_aidm          = sarhead_aidm),(select first_name
                                                                                                from mdx_capture_app_reg_info
                                                                                                where aidm = sarhead_aidm))) spriden_first_name      
      ,nvl((select spriden_mi
            from spriden
                 ,sabiden
            where spriden_change_ind is null
            and   spriden_pidm = sabiden_pidm
            and   sabiden_aidm = sarhead_aidm),(select sarpers_middle_name1
                                                from sarpers
                                                where 1 = 1
                                                and  not exists  (select 'Y'
                                                                  from  sabiden
                                                                  where sabiden_pidm is not null
                                                                  and   sabiden_aidm = sarpers_aidm)
                                                and  sarpers_appl_seqno    = sarhead_appl_seqno
                                                and  sarpers_aidm          = sarhead_aidm)) spriden_mi  
      ,nvl((select to_char(spbpers_birth_date,'DD-MON-YYYY')
            from spbpers
                 ,sabiden
            where 1=1
            and   spbpers_pidm = sabiden_pidm
            and   sabiden_aidm = sarhead_aidm),(select to_char(TO_DATE(sarpers_birth_dte,'MM/DD/YYYY'),'DD-MON-YYYY')
                                                from sarpers
                                                where 1 = 1
                                                and  not exists  (select 'Y'
                                                                  from  sabiden
                                                                  where sabiden_pidm is not null
                                                                  and   sabiden_aidm = sarpers_aidm)
                                                and  sarpers_appl_seqno    = sarhead_appl_seqno
                                                and  sarpers_aidm          = sarhead_aidm)) dob
      ,nvl((select spbpers_name_prefix
            from spbpers
                 ,sabiden
            where 1=1
            and   spbpers_pidm = sabiden_pidm
            and   sabiden_aidm = sarhead_aidm),(select sarpers_prefix
                                                from sarpers
                                                where 1 = 1
                                                and  not exists  (select 'Y'
                                                                  from  sabiden
                                                                  where sabiden_pidm is not null
                                                                  and   sabiden_aidm = sarpers_aidm)
                                                and  sarpers_appl_seqno    = sarhead_appl_seqno
                                                and  sarpers_aidm          = sarhead_aidm)) name_prefix
/*      ,nvl((select decode(a.skvssdt_sdat_code_opt_1 ,'000', ' United Kingdom',skvssdt_short_title )   
            from  skvssdt a
                  ,mdx_ssen_resd i
             where 1 = 1
             and  a.skvssdt_sdat_code_entity = 'HESA' 
             and  a.skvssdt_sdat_code_attr   = 'MDX_DOMICILE'
             and  a.skvssdt_status_ind       = 'A'  
             and  a.skvssdt_eff_date         <= sysdate
             and (a.skvssdt_term_date is null  or a.skvssdt_term_date  >= sysdate)
             and  SKVSSDT_SDAT_CODE_OPT_1    = i.natn_code_dom
             and  i.wsct_code         = 'RESIDENCY'
             and  i.application_no    = sarhead_appl_seqno
             and  i.aidm              = sarhead_aidm  ),'Not Supplied')  resd_desc */
        ,sarhead_aidm
        ,null    skrsain_applicant_no
        ,(select MDX_AGENT_CONTACTS_NAME         agent_name
          from   mdx_agent_contacts 
                ,sarrqst
          where  mdx_agent_contacts_id = sarrqst_ansr_desc
          and    sarrqst_wudq_no       = 202
          and    sarrqst_appl_seqno    = sarhead_appl_seqno
          and    sarrqst_aidm          = sarhead_aidm)  applicant_agent_name
FROM mdx_prog   a
     ,sobcurr
     ,saretry
     ,stvterm
     ,sarhead
WHERE 1 = 1
and  a.mdx_prog_eff_term   = (select max(b.mdx_prog_eff_term)
                              from mdx_prog b
                              where 1 = 1
                              and   b.mdx_prog_eff_term <= sarhead_term_code_entry
                              and   b.mdx_prog_program   = a.mdx_prog_program)
-- jmp jan 2017 start
--and l_agency_code          = (select trim(SARRQST_ANSR_DESC)
--                              from  sarrqst
--                              where sarrqst_wudq_no    = 201
--                              and   sarrqst_aidm       = sarhead_aidm
--                              and   sarrqst_appl_seqno = sarhead_appl_seqno) -- will need to check this works once Jeffs code is done                             
-- jmp jan 2017 end
and  a.mdx_prog_program    = sobcurr_program
and  sobcurr_curr_rule   = SARETRY_CURR_RULE
and  saretry_appl_seqno  = sarhead_appl_seqno
and  saretry_aidm        = sarhead_aidm
and sarhead_term_code_entry in (select SKVSSDT_SHORT_TITLE
                                from skvssdt
                                where 1 = 1
                                and  skvssdt_sdat_code_entity   = 'ONLINEAP'
                                and  skvssdt_sdat_code_attr     = 'RECRUIT_TERM'
                                and  nvl(skvssdt_status_ind,'I') = 'A')
AND stvterm_code          = sarhead_term_code_entry
AND sarhead_appl_comp_ind = 'N'
AND sarhead_process_ind  <> 'P'
and nvl(mdx_agent_portal_pkg.mdx_agent_allow_f
                         (sarhead_aidm             -- aidm
                         ,null   -- pidm
                         ,null        -- skrsain rowid
                         ,sarhead_appl_seqno           -- p_sarhead_appl_seqno
                         ,sarhead_term_code_entry   --p_sarhead_term_code_entry
-- jmp jan 2017 start
                         ,l_agency_codes_all -- jmp l_agency_code  -- p_agency_code           
-- jmp jan 2017 end
                         ,l_agent_id     -- p_agent_id                
                         ,l_view         -- ALL, OWN, GROUP
                         ,l_agent_group_a
                         ,l_agent_group_b      
                         ,l_agent_group_c   
                         ,l_agent_group_d),'N') = 'Y'   -- add in once I sort out the function
--AND sarhead_aidm          = :aidm
union all
-- completed and pushed -- non ucas
-- all pushed applications should have a sabiden_pidm
-- once pushed interested in the saradap record application no
SELECT sabiden_pidm              PIDM
      ,saradap_appl_no
      ,saradap_term_code_entry  -- once pushed take it from the saradap record instead of the sarhead
      ,sarhead_appl_comp_ind
      ,sarhead_process_ind
      ,sarhead_wapp_code
      ,'OA'  application_type
      ,'P'  source_query
      ,SARADAP_PROGRAM_1
      ,a.mdx_prog_long_title
      ,stvterm_DESC 
      ,'~'   application_status   
      ,sarhead_add_date        Application_created    
      ,'D'  skrsain_source -- all online application are source D
      ,saradap_admt_code 
      ,null last_updated  
      ,NVL((select distinct 'Y'
            from skvssdt
                 ,sarchkl
            where 1 = 1
            and skvssdt_eff_date           <= sysdate
            and skvssdt_status_ind         = 'A'
            and skvssdt_sdat_code_attr     = 'PROFES_CHECKS'
            and skvssdt_sdat_code_entity   = 'ONLINEAP'           
            and skvssdt_sdat_code_opt_1    = sarchkl_admr_code
            and sarchkl_ckst_code          is not null
            and sarchkl_appl_no            = saradap_appl_no
            and SARCHKL_TERM_CODE_ENTRY    = saradap_term_code_entry
            and sarchkl_pidm               = saradap_pidm ),'N') professional_checks -- note this will only apply if the decision codes are UF or CF
      ,spriden_id
      ,spriden_last_name
      ,spriden_first_name
      ,spriden_mi
      ,to_char(spbpers_birth_date,'DD-MON-YYYY')
      ,spbpers_name_prefix
/*      ,nvl((select decode(a.skvssdt_sdat_code_opt_1 ,'000', ' United Kingdom',skvssdt_short_title )   
            from  skvssdt a
                  ,mdx_ssen_resd i
             where 1 = 1
             and  a.skvssdt_sdat_code_entity = 'HESA' 
             and  a.skvssdt_sdat_code_attr   = 'MDX_DOMICILE'
             and  a.skvssdt_status_ind       = 'A'  
             and  a.skvssdt_eff_date         <= sysdate
             and (a.skvssdt_term_date is null  or a.skvssdt_term_date  >= sysdate)
             and  SKVSSDT_SDAT_CODE_OPT_1    = skrsain_natn_code_domicile
             and rownum = 1),nvl((select decode(a.skvssdt_sdat_code_opt_1 ,'000', ' United Kingdom',skvssdt_short_title )   
                                  from  skvssdt a
                                       ,mdx_ssen_resd i
                                  where 1 = 1
                                  and  a.skvssdt_sdat_code_entity = 'HESA' 
                                  and  a.skvssdt_sdat_code_attr   = 'MDX_DOMICILE'
                                  and  a.skvssdt_status_ind       = 'A'  
                                  and  a.skvssdt_eff_date         <= sysdate
                                  and (a.skvssdt_term_date is null  or a.skvssdt_term_date  >= sysdate)
                                  and  SKVSSDT_SDAT_CODE_OPT_1    = i.natn_code_dom
                                  and  i.wsct_code         = 'RESIDENCY'
                                  and  i.application_no    = sarhead_appl_seqno
                                  and  i.aidm              = sarhead_aidm  ),'Not Supplied'))  resd_desc */
        ,sarhead_aidm
        ,skrsain_applicant_no
        ,(select MDX_AGENT_CONTACTS_NAME         agent_name
          from   mdx_agent_contacts 
          where  mdx_agent_contacts_id = skrsain_ssdt_code_inst4)  applicant_agent_name
FROM spriden
     ,spbpers
     ,sabiden
     ,skruccr
     ,skrudap 
-- end -- added for agent as need to get to the skrsain values
     ,mdx_prog   a
     ,stvterm
     ,saradap
     ,sarctrl
--     ,stvwapp
     ,sarhead
-- added for agent as need to get to the skrsain values
     ,skrsain    c
WHERE 1 = 1 
and spriden_change_ind       is null
and spriden_pidm             = saradap_pidm
and spbpers_pidm             = saradap_pidm
AND sabiden_aidm             = sarhead_aidm
and skruccr_choice_type_no    = skrudap_choice_no
and SKRUCCR_SSDT_CODE_SBGI    = 'M80'
and skruccr_applicant_no      = skrudap_applicant_no
and skruccr_pidm              = skrudap_pidm
and skrudap_term_code_entry   = saradap_term_code_entry
and skrudap_appl_no           = saradap_appl_no  
and skrudap_pidm              = saradap_pidm 
and a.mdx_prog_eff_term      = (select max(b.mdx_prog_eff_term)
                                from   mdx_prog b
                                where  b.mdx_prog_eff_term <= saradap_term_code_entry
                                and    b.mdx_prog_program   = a.mdx_prog_program)
and a.mdx_prog_program       = saradap_program_1
AND stvterm_code             = saradap_term_code_entry
-- mdx adm start July 2016
and not exists (select 'Y'
                from sarappd
                where 1 = 1
                and   SARAPPD_APDC_CODE       = 'Z'   -- this will exclude where 'Z' decision is in their history
                and   sarappd_term_code_entry = saradap_term_code_entry
                and   SARAPPD_APPL_NO         = saradap_appl_no
                and   sarappd_pidm            = saradap_pidm)
-- mdx adm end July 2016
and saradap_appl_no          = SARCTRL_APPL_NO_SARADAP
and saradap_term_code_entry  = sarhead_term_code_entry
and SARADAP_PIDM             = sabiden_pidm
and  sarctrl_term_code_entry = sarhead_term_code_entry
and  sarctrl_appl_seqno      = sarhead_appl_seqno
and  sarctrl_aidm            = sarhead_aidm
and sarhead_term_code_entry in (select SKVSSDT_SHORT_TITLE
                                from skvssdt
                                where 1 = 1
                                and  skvssdt_sdat_code_entity   = 'ONLINEAP'
                                and  skvssdt_sdat_code_attr     = 'RECRUIT_TERM'
                                and  nvl(skvssdt_status_ind,'I') = 'A')
AND sarhead_appl_comp_ind    = 'Y'
AND sarhead_process_ind      = 'P'
--
-- AGENT START -- added for agent as need to get to the skrsain values   
-- jmp jan 2017 start
--and skrsain_ssdt_code_inst3   = l_agency_code
-- jmp jan 2017 end
and skrsain_applicant_no      = skruccr_applicant_no
and skrsain_pidm              = saradap_pidm 
and skrsain_ssdt_code_inst3   is not null
-- AGENT END
--AND stvwapp_code             = sarhead_wapp_code
--AND sarhead_aidm             = aidm
and nvl(mdx_agent_portal_pkg.mdx_agent_allow_f
                         (null             -- aidm
                         ,saradap_pidm   -- pidm
                         ,c.rowid        -- skrsain rowid
                         ,null           -- p_sarhead_appl_no
                         ,null           --p_sarhead_term_code_entry
-- jmp jan 2017 start
                         ,l_agency_codes_all -- jmp l_agency_code  -- p_agency_code             
-- jmp jan 2017 end
                         ,l_agent_id     -- p_agent_id                
                         ,l_view         -- ALL, OWN, GROUP
                         ,l_agent_group_a
                         ,l_agent_group_b      
                         ,l_agent_group_c   
                         ,l_agent_group_d),'N') = 'Y'
union all
-- UCAS/GTTR & all other direct that did not use the SSB Online Application  
-- note distincting this part of the sql to omit where there are multiple skrsain records
SELECT saradap_pidm              PIDM  
      ,SARADAP_APPL_NO
      ,saradap_term_code_entry
      ,'Y' --sarhead_appl_comp_ind
      ,'P' --sarhead_process_ind
      ,SARADAP_ADMT_CODE --sarhead_wapp_code
      ,'NOA'  application_source
      ,'O'  source_query
      ,SARADAP_PROGRAM_1
      ,a.mdx_prog_long_title
      ,stvterm_DESC 
      ,'~'   application_status
      ,skrsain_appl_date Application_created
      ,skrsain_source
      ,saradap_admt_code 
      ,null last_updated  
      ,NVL((select distinct 'Y'
            from skvssdt
                 ,sarchkl
            where 1 = 1
            and skvssdt_eff_date           <= sysdate
            and skvssdt_status_ind         = 'A'
            and skvssdt_sdat_code_attr     = 'PROFES_CHECKS'
            and skvssdt_sdat_code_entity   = 'ONLINEAP'           
            and skvssdt_sdat_code_opt_1    = sarchkl_admr_code
            and sarchkl_ckst_code          is not null
            and sarchkl_appl_no            = saradap_appl_no
            and SARCHKL_TERM_CODE_ENTRY    = saradap_term_code_entry
            and sarchkl_pidm               = saradap_pidm ),'N') professional_checks -- note this will only apply if the decision codes are UF or CF
      ,spriden_id
      ,spriden_last_name
      ,spriden_first_name
      ,spriden_mi
      ,to_char(spbpers_birth_date,'DD-MON-YYYY')
      ,spbpers_name_prefix
/*      ,nvl((select decode(a.skvssdt_sdat_code_opt_1 ,'000', ' United Kingdom',skvssdt_short_title )   
            from  skvssdt a
                  ,mdx_ssen_resd i
             where 1 = 1
             and  a.skvssdt_sdat_code_entity = 'HESA' 
             and  a.skvssdt_sdat_code_attr   = 'MDX_DOMICILE'
             and  a.skvssdt_status_ind       = 'A'  
             and  a.skvssdt_eff_date         <= sysdate
             and (a.skvssdt_term_date is null  or a.skvssdt_term_date  >= sysdate)
             and  SKVSSDT_SDAT_CODE_OPT_1    = skrsain_natn_code_domicile
             and rownum = 1),'Not Supplied')  resd_desc  */
-- ADM Nov 2016 Offer Letter changes - START
--        ,null --sarhead_aidm
        ,(select sabiden_aidm
          from sabiden
          where sabiden_pidm = spriden_pidm
          and rownum = 1) aidm
-- ADM Nov 2016 Offer Letter changes - END
        ,skrsain_applicant_no
        ,(select MDX_AGENT_CONTACTS_NAME         agent_name
          from   mdx_agent_contacts 
          where  mdx_agent_contacts_id = skrsain_ssdt_code_inst4)  applicant_agent_name
FROM spriden
     ,spbpers
     ,mdx_prog   a
     ,stvterm
     ,skruccr
     ,skrudap
     ,saradap
    -- ,mdx_sabnstu
     ,skrsain    c
WHERE 1 = 1
and spriden_change_ind       is null
and spriden_pidm             = saradap_pidm
and spbpers_Pidm             = saradap_pidm
and a.mdx_prog_eff_term      = (select max(b.mdx_prog_eff_term)
                                from   mdx_prog b
                                where  b.mdx_prog_eff_term <= saradap_term_code_entry
                                and    b.mdx_prog_program   = a.mdx_prog_program)
and a.mdx_prog_program       = saradap_program_1
AND stvterm_code             = saradap_term_code_entry
--and skrsain_ssdt_code_inst4   = l_agent_id
and skruccr_choice_type_no    = skrudap_choice_no
and SKRUCCR_SSDT_CODE_SBGI    = 'M80'
and skruccr_applicant_no      = skrudap_applicant_no
and skruccr_pidm              = skrudap_pidm
and skrudap_term_code_entry   = saradap_term_code_entry
and skrudap_appl_no           = saradap_appl_no  
and not exists (select 'Y'
                from sarctrl
                where 1 = 1
                and sarctrl_appl_no_saradap = saradap_appl_no
                and sarctrl_term_code_entry = saradap_term_code_entry
                and sarctrl_pidm            = saradap_pidm) 
and not exists (select 'Y'
                from sarappd
                where 1 = 1
                and   SARAPPD_APDC_CODE       = 'Z'   -- this will exclude where 'Z' decision is in their history
                and   sarappd_term_code_entry = saradap_term_code_entry
                and   SARAPPD_APPL_NO         = saradap_appl_no
                and   sarappd_pidm            = saradap_pidm)
--
and skrudap_pidm              = saradap_pidm
and saradap_term_code_entry in (select SKVSSDT_SHORT_TITLE
                                from skvssdt
                                where 1 = 1
                                and  skvssdt_sdat_code_entity   = 'ONLINEAP'
                                and  skvssdt_sdat_code_attr     = 'RECRUIT_TERM'
                                and  nvl(skvssdt_status_ind,'I') = 'A')
and SARADAP_ADMT_CODE        not in ('ST','VA','EE') -- not self service online application, validated student or entry error
--
-- jmp jan 2017 start
--and skrsain_ssdt_code_inst3   = l_agency_code
-- jmp jan 2017 end
and skrsain_applicant_no      = skruccr_applicant_no
and skrsain_pidm              = saradap_pidm 
and skrsain_ssdt_code_inst3   is not null
--
-- AGENT START
and nvl(mdx_agent_portal_pkg.mdx_agent_allow_f
                        (null             -- aidm
                         ,saradap_pidm   -- pidm
                         ,c.rowid        -- skrsain rowid
                         ,null           -- p_sarhead_appl_no
                         ,null           --p_sarhead_term_code_entry
-- jmp jan 2017 start
                         ,l_agency_codes_all -- jmp l_agency_code  -- p_agency_code            
-- jmp jan 2017 end
                         ,l_agent_id     -- p_agent_id                
                         ,l_view         -- ALL, OWN, GROUP
                         ,l_agent_group_a
                         ,l_agent_group_b      
                         ,l_agent_group_c   
                         ,l_agent_group_d),'N') = 'Y'     
-- AGENT END
--
order by 11 /*start term*/,19 /* Family name */,20 /*First name*/;
--and saradap_pidm             = pidm; */   
--
cursor get_details_exist is
select 'y'
from dual
where exists
-- submitted but not processed
(SELECT 'y'
FROM --sabiden 
     mdx_prog   a
     ,sobcurr
     ,saretry
     ,stvterm
     ,sarhead
WHERE 1 = 2
and  a.mdx_prog_eff_term   = (select max(b.mdx_prog_eff_term)
                              from mdx_prog b
                              where 1 = 1
                              and   b.mdx_prog_eff_term <= sarhead_term_code_entry
                              and   b.mdx_prog_program   = a.mdx_prog_program)
and  a.mdx_prog_program    = sobcurr_program
and nvl(mdx_agent_portal_pkg.mdx_agent_allow_f
                        (sarhead_aidm             -- aidm
                         ,null   -- pidm
                         ,null        -- skrsain rowid
                         ,sarhead_appl_seqno           -- p_sarhead_appl_seqno
                         ,sarhead_term_code_entry   --p_sarhead_term_code_entry
-- jmp jan 2017 start
                         ,l_agency_codes_all -- jmp l_agency_code  -- p_agency_code          
-- jmp jan 2017 end
                         ,l_agent_id     -- p_agent_id                
                         ,l_view         -- ALL, OWN, GROUP
                         ,l_agent_group_a
                         ,l_agent_group_b      
                         ,l_agent_group_c   
                         ,l_agent_group_d),'N') = 'Y'   -- add in once I sort out the function
-- jmp jan 2017 start
--and l_agency_code          = (select trim(SARRQST_ANSR_DESC)
--                              from  sarrqst
--                              where sarrqst_wudq_no    = 201
--                              and   sarrqst_aidm       = sarhead_aidm
--                              and   sarrqst_appl_seqno = sarhead_appl_seqno) -- will need to check this works once Jeffs code is done 
-- jmp jan 2017 end
and  sobcurr_curr_rule   = SARETRY_CURR_RULE
and  saretry_appl_seqno  = sarhead_appl_seqno
and  saretry_aidm        = sarhead_aidm
AND stvterm_code          = sarhead_term_code_entry
AND sarhead_appl_comp_ind = 'Y'
AND sarhead_process_ind  <> 'P'
--AND sarhead_aidm          = :aidm
and sarhead_term_code_entry in (select SKVSSDT_SHORT_TITLE
                                from skvssdt
                                where 1 = 1
                                and  skvssdt_sdat_code_entity   = 'ONLINEAP'
                                and  skvssdt_sdat_code_attr     = 'RECRUIT_TERM'
                                and  nvl(skvssdt_status_ind,'I') = 'A')
)
or exists
-- incomplete
(SELECT 'y'
FROM mdx_prog   a
     ,sobcurr
     ,saretry
     ,stvterm
     ,sarhead
WHERE 1 = 2
and  a.mdx_prog_eff_term   = (select max(b.mdx_prog_eff_term)
                              from mdx_prog b
                              where 1 = 1
                              and   b.mdx_prog_eff_term <= sarhead_term_code_entry
                              and   b.mdx_prog_program   = a.mdx_prog_program)
and nvl(mdx_agent_portal_pkg.mdx_agent_allow_f
                         (sarhead_aidm             -- aidm
                         ,null   -- pidm
                         ,null        -- skrsain rowid
                         ,sarhead_appl_seqno           -- p_sarhead_appl_seqno
                         ,sarhead_term_code_entry   --p_sarhead_term_code_entry
-- jmp jan 2017 start
                         ,l_agency_codes_all -- jmp l_agency_code  -- p_agency_code             
-- jmp jan 2017 end
                         ,l_agent_id     -- p_agent_id                
                         ,l_view         -- ALL, OWN, GROUP
                         ,l_agent_group_a
                         ,l_agent_group_b      
                         ,l_agent_group_c   
                         ,l_agent_group_d),'N') = 'Y'   -- add in once I sort out the function
-- jmp jan 2017 start
--and l_agency_code          = (select trim(SARRQST_ANSR_DESC)
--                              from  sarrqst
--                              where sarrqst_wudq_no    = 201
--                              and   sarrqst_aidm       = sarhead_aidm
--                              and   sarrqst_appl_seqno = sarhead_appl_seqno) -- will need to check this works once Jeffs code is done                             
-- jmp jan 2017 end
and  a.mdx_prog_program    = sobcurr_program
and  sobcurr_curr_rule   = SARETRY_CURR_RULE
and  saretry_appl_seqno  = sarhead_appl_seqno
and  saretry_aidm        = sarhead_aidm
AND stvterm_code          = sarhead_term_code_entry
AND sarhead_appl_comp_ind = 'N'
AND sarhead_process_ind  <> 'P'
--AND sarhead_aidm          = :aidm
and sarhead_term_code_entry in (select SKVSSDT_SHORT_TITLE
                                from skvssdt
                                where 1 = 1
                                and  skvssdt_sdat_code_entity   = 'ONLINEAP'
                                and  skvssdt_sdat_code_attr     = 'RECRUIT_TERM'
                                and  nvl(skvssdt_status_ind,'I') = 'A')
)
or exists
-- completed and pushed -- non ucas
-- all pushed applications should have a sabiden_pidm
-- once pushed interested in the saradap record application no
(SELECT 'y'
FROM spriden
     ,spbpers
     ,sabiden
-- added for agent as need to get to the skrsain values
     ,skrsain    c
     ,skruccr
     ,skrudap 
-- end -- added for agent as need to get to the skrsain values
     ,mdx_prog   a
     ,stvterm
     ,saradap
     ,sarctrl
     ,stvwapp
     ,sarhead
WHERE 1 = 2
and spriden_change_ind       is null
and spriden_pidm             = saradap_pidm
and spbpers_pidm             = saradap_pidm
AND sabiden_aidm             = sarhead_aidm
-- AGENT START -- added for agent as need to get to the skrsain values
and nvl(mdx_agent_portal_pkg.mdx_agent_allow_f
                         (null             -- aidm
                         ,saradap_pidm   -- pidm
                         ,c.rowid        -- skrsain rowid
                         ,null           -- p_sarhead_appl_no
                         ,null           --p_sarhead_term_code_entry
-- jmp jan 2017 start
                         ,l_agency_codes_all -- jmp l_agency_code  -- p_agency_code            
-- jmp jan 2017 end
                         ,l_agent_id     -- p_agent_id                
                         ,l_view         -- ALL, OWN, GROUP
                         ,l_agent_group_a
                         ,l_agent_group_b      
                         ,l_agent_group_c   
                         ,l_agent_group_d),'N') = 'Y'    
-- jmp jan 2017 start
--and skrsain_ssdt_code_inst3   = l_agency_code
-- jmp jan 2017 end
and skrsain_applicant_no      = skruccr_applicant_no
and skrsain_pidm              = saradap_pidm 
and skruccr_choice_type_no    = skrudap_choice_no
and SKRUCCR_SSDT_CODE_SBGI    = 'M80'
and skruccr_applicant_no      = skrudap_applicant_no
and skruccr_pidm              = skrudap_pidm
and skrudap_term_code_entry   = saradap_term_code_entry
and skrudap_appl_no           = saradap_appl_no  
and skrudap_pidm              = saradap_pidm 
-- AGENT END
and a.mdx_prog_eff_term      = (select max(b.mdx_prog_eff_term)
                                from   mdx_prog b
                                where  b.mdx_prog_eff_term <= saradap_term_code_entry
                                and    b.mdx_prog_program   = a.mdx_prog_program)
and a.mdx_prog_program       = saradap_program_1
AND stvterm_code             = saradap_term_code_entry
-- mdx adm start July 2016
and not exists (select 'Y'
                from sarappd
                where 1 = 1
                and   SARAPPD_APDC_CODE       = 'Z'   -- this will exclude where 'Z' decision is in their history
                and   sarappd_term_code_entry = saradap_term_code_entry
                and   SARAPPD_APPL_NO         = saradap_appl_no
                and   sarappd_pidm            = saradap_pidm)
-- mdx adm end July 2016
and saradap_appl_no          = SARCTRL_APPL_NO_SARADAP
and saradap_term_code_entry  = sarhead_term_code_entry
and SARADAP_PIDM             = sabiden_pidm
and  sarctrl_term_code_entry = sarhead_term_code_entry
and  sarctrl_appl_seqno      = sarhead_appl_seqno
and  sarctrl_aidm            = sarhead_aidm
AND sarhead_appl_comp_ind    = 'Y'
AND sarhead_process_ind      = 'P'
AND stvwapp_code             = sarhead_wapp_code
--AND sarhead_aidm             = aidm
and sarhead_term_code_entry in (select SKVSSDT_SHORT_TITLE
                                from skvssdt
                                where 1 = 1
                                and  skvssdt_sdat_code_entity   = 'ONLINEAP'
                                and  skvssdt_sdat_code_attr     = 'RECRUIT_TERM'
                                and  nvl(skvssdt_status_ind,'I') = 'A')
)
or exists
-- UCAS/GTTR & all other direct that did not use the SSB Online Application  
-- note distincting this part of the sql to omit where there are multiple skrsain records
(SELECT 'y'
FROM spriden
     ,spbpers
     ,mdx_prog   a
     ,stvterm
     ,skrsain    c
     ,skruccr
     ,skrudap
     ,saradap
    -- ,mdx_sabnstu
WHERE 1 = 2
and spriden_change_ind       is null
and spriden_pidm             = saradap_pidm
and spbpers_Pidm             = saradap_pidm
and a.mdx_prog_eff_term      = (select max(b.mdx_prog_eff_term)
                                from   mdx_prog b
                                where  b.mdx_prog_eff_term <= saradap_term_code_entry
                                and    b.mdx_prog_program   = a.mdx_prog_program)
and a.mdx_prog_program       = saradap_program_1
AND stvterm_code             = saradap_term_code_entry
--and skrsain_ssdt_code_inst4   = l_agent_id
-- AGENT START
and nvl(mdx_agent_portal_pkg.mdx_agent_allow_f
                        (null             -- aidm
                         ,saradap_pidm   -- pidm
                         ,c.rowid        -- skrsain rowid
                         ,null           -- p_sarhead_appl_no
                         ,null           --p_sarhead_term_code_entry
-- jmp jan 2017 start
                         ,l_agency_codes_all -- jmp l_agency_code  -- p_agency_code              
-- jmp jan 2017 end
                         ,l_agent_id     -- p_agent_id                
                         ,l_view         -- ALL, OWN, GROUP
                         ,l_agent_group_a
                         ,l_agent_group_b      
                         ,l_agent_group_c   
                         ,l_agent_group_d),'N') = 'Y'     
-- AGENT END
-- jmp jan 2017 start
--and skrsain_ssdt_code_inst3   = l_agency_code
-- jmp jan 2017 end
and skrsain_applicant_no      = skruccr_applicant_no
and skrsain_pidm              = saradap_pidm 
and skruccr_choice_type_no    = skrudap_choice_no
and SKRUCCR_SSDT_CODE_SBGI    = 'M80'
and skruccr_applicant_no      = skrudap_applicant_no
and skruccr_pidm              = skrudap_pidm
and skrudap_term_code_entry   = saradap_term_code_entry
and skrudap_appl_no           = saradap_appl_no  
and skrudap_pidm              = saradap_pidm
and saradap_term_code_entry in (select SKVSSDT_SHORT_TITLE
                                from skvssdt
                                where 1 = 1
                                and  skvssdt_sdat_code_entity   = 'ONLINEAP'
                                and  skvssdt_sdat_code_attr     = 'RECRUIT_TERM'
                                and  nvl(skvssdt_status_ind,'I') = 'A')
and SARADAP_ADMT_CODE        not in ('ST','VA','EE') -- not self service online application, validated student or entry error
and not exists (select 'Y'
                from sarctrl
                where 1 = 1
                and sarctrl_appl_no_saradap = saradap_appl_no
                and sarctrl_term_code_entry = saradap_term_code_entry
                and sarctrl_pidm            = saradap_pidm) 
and not exists (select 'Y'
                from sarappd
                where 1 = 1
                and   SARAPPD_APDC_CODE       = 'Z'   -- this will exclude where 'Z' decision is in their history
                and   sarappd_term_code_entry = saradap_term_code_entry
                and   SARAPPD_APPL_NO         = saradap_appl_no
                and   sarappd_pidm            = saradap_pidm)
);
--
cursor get_details_check_c is
-- THIS CUSOR IS A DUPLICAT OF THE get_details_check_c but only returning one field and one row per union
-- this is used to just check at least 1 application is returned for the Agent
-- submitted but not processed
SELECT 'OAS'                   application_type
FROM --sabiden 
     mdx_prog   a
     ,sobcurr
     ,saretry
     ,stvterm
     ,sarhead
WHERE 1 = 1
and  a.mdx_prog_eff_term   = (select max(b.mdx_prog_eff_term)
                              from mdx_prog b
                              where 1 = 1
                              and   b.mdx_prog_eff_term <= sarhead_term_code_entry
                              and   b.mdx_prog_program   = a.mdx_prog_program)
and  a.mdx_prog_program    = sobcurr_program
and nvl(mdx_agent_portal_pkg.mdx_agent_allow_f
                        (sarhead_aidm             -- aidm
                         ,null   -- pidm
                         ,null        -- skrsain rowid
                         ,sarhead_appl_seqno           -- p_sarhead_appl_seqno
                         ,sarhead_term_code_entry   --p_sarhead_term_code_entry
-- jmp jan 2017 start
                         ,l_agency_codes_all -- jmp l_agency_code  -- p_agency_code           
-- jmp jan 2017 end
                         ,l_agent_id     -- p_agent_id                
                         ,l_view         -- ALL, OWN, GROUP
                         ,l_agent_group_a
                         ,l_agent_group_b      
                         ,l_agent_group_c   
                         ,l_agent_group_d),'N') = 'Y'   -- add in once I sort out the function
-- jmp jan 2017 start
--and l_agency_code          = (select trim(SARRQST_ANSR_DESC)
--                              from  sarrqst
--                              where sarrqst_wudq_no    = 201
--                              and   sarrqst_aidm       = sarhead_aidm
--                              and   sarrqst_appl_seqno = sarhead_appl_seqno) -- will need to check this works once Jeffs code is done 
-- jmp jan 2017 end
and  sobcurr_curr_rule   = SARETRY_CURR_RULE
and  saretry_appl_seqno  = sarhead_appl_seqno
and  saretry_aidm        = sarhead_aidm
AND stvterm_code          = sarhead_term_code_entry
AND sarhead_appl_comp_ind = 'Y'
AND sarhead_process_ind  <> 'P'
--AND sarhead_aidm          = :aidm
and sarhead_term_code_entry in (select SKVSSDT_SHORT_TITLE
                                from skvssdt
                                where 1 = 1
                                and  skvssdt_sdat_code_entity   = 'ONLINEAP'
                                and  skvssdt_sdat_code_attr     = 'RECRUIT_TERM'
                                and  nvl(skvssdt_status_ind,'I') = 'A')
and rownum = 1
union all
-- incomplete
SELECT 'OAI'  application_type
FROM mdx_prog   a
     ,sobcurr
     ,saretry
     ,stvterm
     ,sarhead
WHERE 1 = 1
and  a.mdx_prog_eff_term   = (select max(b.mdx_prog_eff_term)
                              from mdx_prog b
                              where 1 = 1
                              and   b.mdx_prog_eff_term <= sarhead_term_code_entry
                              and   b.mdx_prog_program   = a.mdx_prog_program)
and nvl(mdx_agent_portal_pkg.mdx_agent_allow_f
                         (sarhead_aidm             -- aidm
                         ,null   -- pidm
                         ,null        -- skrsain rowid
                         ,sarhead_appl_seqno           -- p_sarhead_appl_seqno
                         ,sarhead_term_code_entry   --p_sarhead_term_code_entry
-- jmp jan 2017 start
                         ,l_agency_codes_all -- jmp l_agency_code  -- p_agency_code            
-- jmp jan 2017 end
                         ,l_agent_id     -- p_agent_id                
                         ,l_view         -- ALL, OWN, GROUP
                         ,l_agent_group_a
                         ,l_agent_group_b      
                         ,l_agent_group_c   
                         ,l_agent_group_d),'N') = 'Y'   -- add in once I sort out the function
-- jmp jan 2017 start
--and l_agency_code          = (select trim(SARRQST_ANSR_DESC)
--                              from  sarrqst
--                              where sarrqst_wudq_no    = 201
--                              and   sarrqst_aidm       = sarhead_aidm
--                              and   sarrqst_appl_seqno = sarhead_appl_seqno) -- will need to check this works once Jeffs code is done                             
-- jmp jan 2017 end
and  a.mdx_prog_program    = sobcurr_program
and  sobcurr_curr_rule   = SARETRY_CURR_RULE
and  saretry_appl_seqno  = sarhead_appl_seqno
and  saretry_aidm        = sarhead_aidm
AND stvterm_code          = sarhead_term_code_entry
AND sarhead_appl_comp_ind = 'N'
AND sarhead_process_ind  <> 'P'
--AND sarhead_aidm          = :aidm
and sarhead_term_code_entry in (select SKVSSDT_SHORT_TITLE
                                from skvssdt
                                where 1 = 1
                                and  skvssdt_sdat_code_entity   = 'ONLINEAP'
                                and  skvssdt_sdat_code_attr     = 'RECRUIT_TERM'
                                and  nvl(skvssdt_status_ind,'I') = 'A')
and rownum = 1
union all
-- completed and pushed -- non ucas
-- all pushed applications should have a sabiden_pidm
-- once pushed interested in the saradap record application no
SELECT 'OAP'  application_type
FROM spriden
     ,spbpers
     ,sabiden
-- added for agent as need to get to the skrsain values
     ,skrsain    c
     ,skruccr
     ,skrudap 
-- end -- added for agent as need to get to the skrsain values
     ,mdx_prog   a
     ,stvterm
     ,saradap
     ,sarctrl
     ,stvwapp
     ,sarhead
WHERE 1 = 1
and spriden_change_ind       is null
and spriden_pidm             = saradap_pidm
and spbpers_pidm             = saradap_pidm
AND sabiden_aidm             = sarhead_aidm
-- AGENT START -- added for agent as need to get to the skrsain values
and nvl(mdx_agent_portal_pkg.mdx_agent_allow_f
                         (null             -- aidm
                         ,saradap_pidm   -- pidm
                         ,c.rowid        -- skrsain rowid
                         ,null           -- p_sarhead_appl_no
                         ,null           --p_sarhead_term_code_entry
-- jmp jan 2017 start
                         ,l_agency_codes_all -- jmp l_agency_code  -- p_agency_code             
-- jmp jan 2017 end
                         ,l_agent_id     -- p_agent_id                
                         ,l_view         -- ALL, OWN, GROUP
                         ,l_agent_group_a
                         ,l_agent_group_b      
                         ,l_agent_group_c   
                         ,l_agent_group_d),'N') = 'Y' 
-- jmp jan 2017 start   
--and skrsain_ssdt_code_inst3   = l_agency_code
-- jmp jan 2017 end
and skrsain_applicant_no      = skruccr_applicant_no
and skrsain_pidm              = saradap_pidm 
and skruccr_choice_type_no    = skrudap_choice_no
and SKRUCCR_SSDT_CODE_SBGI    = 'M80'
and skruccr_applicant_no      = skrudap_applicant_no
and skruccr_pidm              = skrudap_pidm
and skrudap_term_code_entry   = saradap_term_code_entry
and skrudap_appl_no           = saradap_appl_no  
and skrudap_pidm              = saradap_pidm 
-- AGENT END
and a.mdx_prog_eff_term      = (select max(b.mdx_prog_eff_term)
                                from   mdx_prog b
                                where  b.mdx_prog_eff_term <= saradap_term_code_entry
                                and    b.mdx_prog_program   = a.mdx_prog_program)
and a.mdx_prog_program       = saradap_program_1
AND stvterm_code             = saradap_term_code_entry
-- mdx adm start July 2016
and not exists (select 'Y'
                from sarappd
                where 1 = 1
                and   SARAPPD_APDC_CODE       = 'Z'   -- this will exclude where 'Z' decision is in their history
                and   sarappd_term_code_entry = saradap_term_code_entry
                and   SARAPPD_APPL_NO         = saradap_appl_no
                and   sarappd_pidm            = saradap_pidm)
-- mdx adm end July 2016
and saradap_appl_no          = SARCTRL_APPL_NO_SARADAP
and saradap_term_code_entry  = sarhead_term_code_entry
and SARADAP_PIDM             = sabiden_pidm
and  sarctrl_term_code_entry = sarhead_term_code_entry
and  sarctrl_appl_seqno      = sarhead_appl_seqno
and  sarctrl_aidm            = sarhead_aidm
AND sarhead_appl_comp_ind    = 'Y'
AND sarhead_process_ind      = 'P'
AND stvwapp_code             = sarhead_wapp_code
--AND sarhead_aidm             = aidm
and sarhead_term_code_entry in (select SKVSSDT_SHORT_TITLE
                                from skvssdt
                                where 1 = 1
                                and  skvssdt_sdat_code_entity   = 'ONLINEAP'
                                and  skvssdt_sdat_code_attr     = 'RECRUIT_TERM'
                                and  nvl(skvssdt_status_ind,'I') = 'A')
and rownum = 1
union all
-- UCAS/GTTR & all other direct that did not use the SSB Online Application  
-- note distincting this part of the sql to omit where there are multiple skrsain records
SELECT 'NOA'  application_source
FROM spriden
     ,spbpers
     ,mdx_prog   a
     ,stvterm
     ,skrsain    c
     ,skruccr
     ,skrudap
     ,saradap
    -- ,mdx_sabnstu
WHERE 1 = 1
and spriden_change_ind       is null
and spriden_pidm             = saradap_pidm
and spbpers_Pidm             = saradap_pidm
and a.mdx_prog_eff_term      = (select max(b.mdx_prog_eff_term)
                                from   mdx_prog b
                                where  b.mdx_prog_eff_term <= saradap_term_code_entry
                                and    b.mdx_prog_program   = a.mdx_prog_program)
and a.mdx_prog_program       = saradap_program_1
AND stvterm_code             = saradap_term_code_entry
--and skrsain_ssdt_code_inst4   = l_agent_id
-- AGENT START
and nvl(mdx_agent_portal_pkg.mdx_agent_allow_f
                        (null             -- aidm
                         ,saradap_pidm   -- pidm
                         ,c.rowid        -- skrsain rowid
                         ,null           -- p_sarhead_appl_no
                         ,null           --p_sarhead_term_code_entry
-- jmp jan 2017 start
                         ,l_agency_codes_all -- jmp l_agency_code  -- p_agency_code            
-- jmp jan 2017 end
                         ,l_agent_id     -- p_agent_id                
                         ,l_view         -- ALL, OWN, GROUP
                         ,l_agent_group_a
                         ,l_agent_group_b      
                         ,l_agent_group_c   
                         ,l_agent_group_d),'N') = 'Y'     
-- AGENT END
-- jmp jan 2017 start
--and skrsain_ssdt_code_inst3   = l_agency_code
-- jmp jan 2017 end
and skrsain_applicant_no      = skruccr_applicant_no
and skrsain_pidm              = saradap_pidm 
and skruccr_choice_type_no    = skrudap_choice_no
and SKRUCCR_SSDT_CODE_SBGI    = 'M80'
and skruccr_applicant_no      = skrudap_applicant_no
and skruccr_pidm              = skrudap_pidm
and skrudap_term_code_entry   = saradap_term_code_entry
and skrudap_appl_no           = saradap_appl_no  
and skrudap_pidm              = saradap_pidm
and saradap_term_code_entry in (select SKVSSDT_SHORT_TITLE
                                from skvssdt
                                where 1 = 1
                                and  skvssdt_sdat_code_entity   = 'ONLINEAP'
                                and  skvssdt_sdat_code_attr     = 'RECRUIT_TERM'
                                and  nvl(skvssdt_status_ind,'I') = 'A')
and SARADAP_ADMT_CODE        not in ('ST','VA','EE') -- not self service online application, validated student or entry error
and not exists (select 'Y'
                from sarctrl
                where 1 = 1
                and sarctrl_appl_no_saradap = saradap_appl_no
                and sarctrl_term_code_entry = saradap_term_code_entry
                and sarctrl_pidm            = saradap_pidm) 
and not exists (select 'Y'
                from sarappd
                where 1 = 1
                and   SARAPPD_APDC_CODE       = 'Z'   -- this will exclude where 'Z' decision is in their history
                and   sarappd_term_code_entry = saradap_term_code_entry
                and   SARAPPD_APPL_NO         = saradap_appl_no
                and   sarappd_pidm            = saradap_pidm)
and rownum = 1;
--    
cursor get_decision_details_c (p_current varchar2, p_earlier varchar2 )is
select (select sarappd_apdc_code
        from sarappd a
        where 1 = 1
        and a.sarappd_seq_no    = (select max(b.sarappd_seq_no)
                                   from sarappd b
                                   where 1 = 1
                                   and b.sarappd_term_code_entry  = a.sarappd_term_code_entry
                                   and b.sarappd_appl_no          = a.sarappd_appl_no                         
                                   and b.sarappd_pidm             = a.sarappd_pidm
                                   and trunc(b.sarappd_apdc_date) = trunc(a.sarappd_apdc_date))
        and a.sarappd_apdc_date = (select max(b.sarappd_apdc_date)
                                   from sarappd b
                                   where 1 = 1
                                   and b.sarappd_term_code_entry = a.sarappd_term_code_entry
                                   and b.sarappd_appl_no         = a.sarappd_appl_no                         
                                   and b.sarappd_pidm            = a.sarappd_pidm)
        and a.sarappd_term_code_entry = l_term_code_entry
        and a.sarappd_appl_no         = l_appno                      
        and a.sarappd_pidm            = l_pidm)      actual_max_decision_code -- for my actions
       ,(select sarappd_apdc_date
        from sarappd a
        where 1 = 1
        and a.sarappd_seq_no    = (select max(b.sarappd_seq_no)
                                   from sarappd b
                                   where 1 = 1
                                   and b.sarappd_term_code_entry  = a.sarappd_term_code_entry
                                   and b.sarappd_appl_no          = a.sarappd_appl_no                         
                                   and b.sarappd_pidm             = a.sarappd_pidm
                                   and trunc(b.sarappd_apdc_date) = trunc(a.sarappd_apdc_date))
        and a.sarappd_apdc_date = (select max(b.sarappd_apdc_date)
                                   from sarappd b
                                   where 1 = 1
                                   and b.sarappd_term_code_entry = a.sarappd_term_code_entry
                                   and b.sarappd_appl_no         = a.sarappd_appl_no                         
                                   and b.sarappd_pidm            = a.sarappd_pidm)
        and a.sarappd_term_code_entry = l_term_code_entry
        and a.sarappd_appl_no         = l_appno                      
        and a.sarappd_pidm            = l_pidm)      actual_max_decision_date -- for my actions
       ,nvl((select distinct 'Y'
             from sarappd a
             where 1 = 1
             and a.sarappd_apdc_code        in ('UF')
             and a.sarappd_term_code_entry = l_term_code_entry
             and a.sarappd_appl_no         = l_appno                        
             and a.sarappd_pidm             = l_pidm),'N')   l_UF_Decision_YN                     
      ,nvl((select a.sarappd_apdc_code
            from sarappd a
            where 1 = 1
            -- ADM Nov 2016 Offer Letter changes - START
           /* and not exists (select distinct 'Y'
                             from sarappd a
                             where 1 = 1
                             and a.sarappd_apdc_code        in ('U','UF')
                             and a.sarappd_term_code_entry = l_term_code_entry
                             and a.sarappd_appl_no         = l_appno                        
                             and a.sarappd_pidm            = l_pidm)
           */
           -- ADM Nov 2016 Offer Letter changes - END
            and a.sarappd_seq_no    = (select max(b.sarappd_seq_no)
                                       from sarappd b
                                       where 1 = 1
                                       -- ADM Nov 2016 Offer Letter changes - START
                                       and b.sarappd_apdc_code        in ('C','CD','CF','CI','U','UF','UD','UI','UP','R','W')--('C','CD','CF','CI','U','UF','UD','UI','UP')
                                       -- ADM Nov 2016 Offer Letter changes - END
                                       and b.sarappd_term_code_entry  = a.sarappd_term_code_entry
                                       and b.sarappd_appl_no          = a.sarappd_appl_no                         
                                       and b.sarappd_pidm             = a.sarappd_pidm
                                       and trunc(b.sarappd_apdc_date) = trunc(a.sarappd_apdc_date))
            and a.sarappd_apdc_date = (select max(b.sarappd_apdc_date)
                                       from sarappd b
                                       where 1 = 1
                                       -- ADM Nov 2016 Offer Letter changes - START
                                       and b.sarappd_apdc_code        in ('C','CD','CF','CI','U','UF','UD','UI','UP','R','W')--('C','CD','CF','CI','U','UF','UD','UI','UP')
                                       -- ADM Nov 2016 Offer Letter changes - END
                                       and b.sarappd_term_code_entry = a.sarappd_term_code_entry
                                       and b.sarappd_appl_no         = a.sarappd_appl_no                         
                                       and b.sarappd_pidm            = a.sarappd_pidm)
            -- ADM Nov 2016 Offer Letter changes - START                           
            and a.sarappd_apdc_code        in ('C','CD','CF','CI','U','UF','UD','UI','UP','R','W')--('C','CD','CF','CI','U','UF','UD','UI','UP')
            -- ADM Nov 2016 Offer Letter changes - END
            and a.sarappd_term_code_entry = l_term_code_entry
            and a.sarappd_appl_no         = l_appno                       
            and a.sarappd_pidm            = l_pidm),'~')   l_C_Decision   
       ,(select c.skrudec_decn_seq-- c.rowid--c.skrudec_off_lib_string
             from skrudec  c
                 ,skrudap
                 ,sarappd  a
             where 1 = 1
             and c.skrudec_decn_seq        = (select max(d.skrudec_decn_seq)
                                              from skrudec d
                                              where 1 = 1
                                              and d.skrudec_off_lib_string  is not null
                                              and d.skrudec_choice_type_no  = c.skrudec_choice_type_no
                                              and d.skrudec_pidm            = c.skrudec_pidm)                                                             
             and c.skrudec_choice_type_no  = skrudap_choice_no
             and c.skrudec_pidm            = skrudap_pidm  
             and skrudap_term_code_entry   = a.sarappd_term_code_entry
             and skrudap_appl_no           = a.sarappd_appl_no  
             and skrudap_pidm              = a.sarappd_pidm
             and a.sarappd_seq_no          = (select max(b.sarappd_seq_no)
                                              from sarappd b
                                              where 1 = 1
                                              and b.sarappd_apdc_code        in ('C','CD','CF','CI')
                                              and b.sarappd_term_code_entry  = a.sarappd_term_code_entry
                                              and b.sarappd_appl_no          = a.sarappd_appl_no                         
                                              and b.sarappd_pidm             = a.sarappd_pidm
                                              and trunc(b.sarappd_apdc_date) = trunc(a.sarappd_apdc_date))
            and a.sarappd_apdc_date         = (select max(b.sarappd_apdc_date)
                                              from sarappd b
                                              where 1 = 1
                                              and b.sarappd_apdc_code        in ('C','CD','CF','CI')
                                              and b.sarappd_term_code_entry = a.sarappd_term_code_entry
                                              and b.sarappd_appl_no         = a.sarappd_appl_no
                                              and b.sarappd_pidm            = a.sarappd_pidm)                         
           and a.sarappd_apdc_code        in ('C','CD','CF','CI')
           and a.sarappd_term_code_entry = l_term_code_entry
           and a.sarappd_appl_no         = l_appno                        
           and a.sarappd_pidm            = l_pidm)  offer_string                             
from  dual
where p_current = 'Y'
union
-- embargo active -- this will only be invoked for saradap_admt_code = 9 and skrsain_source = U
select nvl((select sarappd_apdc_code
        from sarappd a
        where 1 = 1
        and a.sarappd_seq_no    = (select max(b.sarappd_seq_no)
                                   from sarappd b
                                   where 1 = 1
                                   and b.sarappd_apdc_date       < l_embargo_start_date
                                   and b.sarappd_term_code_entry  = a.sarappd_term_code_entry
                                   and b.sarappd_appl_no          = a.sarappd_appl_no                         
                                   and b.sarappd_pidm             = a.sarappd_pidm
                                   and trunc(b.sarappd_apdc_date) = trunc(a.sarappd_apdc_date))
        and a.sarappd_apdc_date = (select max(b.sarappd_apdc_date)
                                   from sarappd b
                                   where 1 = 1
                                   and b.sarappd_apdc_date       < l_embargo_start_date
                                   and b.sarappd_term_code_entry = a.sarappd_term_code_entry
                                   and b.sarappd_appl_no         = a.sarappd_appl_no                         
                                   and b.sarappd_pidm            = a.sarappd_pidm)
        and a.sarappd_apdc_date       < l_embargo_start_date
        and a.sarappd_term_code_entry = l_term_code_entry
        and a.sarappd_appl_no         = l_appno                      
        and a.sarappd_pidm            = l_pidm),'AA')      actual_max_decision_code -- for my actions -- UCAS during embargo default AA if the only decision they have falls within the embargo
      ,(select sarappd_apdc_date
        from sarappd a
        where 1 = 1
        and a.sarappd_seq_no    = (select max(b.sarappd_seq_no)
                                   from sarappd b
                                   where 1 = 1
                                   and b.sarappd_apdc_date       < l_embargo_start_date
                                   and b.sarappd_term_code_entry  = a.sarappd_term_code_entry
                                   and b.sarappd_appl_no          = a.sarappd_appl_no                         
                                   and b.sarappd_pidm             = a.sarappd_pidm
                                   and trunc(b.sarappd_apdc_date) = trunc(a.sarappd_apdc_date))
        and a.sarappd_apdc_date = (select max(b.sarappd_apdc_date)
                                   from sarappd b
                                   where 1 = 1
                                   and b.sarappd_apdc_date       < l_embargo_start_date
                                   and b.sarappd_term_code_entry = a.sarappd_term_code_entry
                                   and b.sarappd_appl_no         = a.sarappd_appl_no                         
                                   and b.sarappd_pidm            = a.sarappd_pidm)
        and a.sarappd_apdc_date       < l_embargo_start_date
        and a.sarappd_term_code_entry = l_term_code_entry
        and a.sarappd_appl_no         = l_appno                      
        and a.sarappd_pidm            = l_pidm)      actual_max_decision_date -- for my actions
       ,nvl((select distinct 'Y'
             from sarappd a
             where 1 = 1
             and a.sarappd_apdc_date       < l_embargo_start_date
             and a.sarappd_apdc_code        in ('UF')
             and a.sarappd_term_code_entry = l_term_code_entry
             and a.sarappd_appl_no         = l_appno                        
             and a.sarappd_pidm             = l_pidm),'N')   l_UF_Decision_YN                     
      ,nvl((select a.sarappd_apdc_code
            from sarappd a
            where 1 = 1
            -- ADM Nov 2016 Offer Letter changes - START
            /*
            and not exists  (select distinct 'Y'
                             from sarappd a
                             where 1 = 1
                             and a.sarappd_apdc_date       < l_embargo_start_date
                             and a.sarappd_apdc_code        in ('U','UF')
                             and a.sarappd_term_code_entry = l_term_code_entry
                             and a.sarappd_appl_no         = l_appno                        
                             and a.sarappd_pidm            = l_pidm)
            */
            -- ADM Nov 2016 Offer Letter changes - END
            and a.sarappd_seq_no    = (select max(b.sarappd_seq_no)
                                       from sarappd b
                                       where 1 = 1
                                       and b.sarappd_apdc_date       < l_embargo_start_date
                                       -- ADM Nov 2016 Offer Letter changes - START
                                       and b.sarappd_apdc_code        in ('C','CD','CF','CI','U','UF','UD','UI','UP','R','W')--('C','CD','CF','CI','U','UF','UD','UI','UP')
                                       -- ADM Nov 2016 Offer Letter changes - END
                                       and b.sarappd_term_code_entry  = a.sarappd_term_code_entry
                                       and b.sarappd_appl_no          = a.sarappd_appl_no                         
                                       and b.sarappd_pidm             = a.sarappd_pidm
                                       and trunc(b.sarappd_apdc_date) = trunc(a.sarappd_apdc_date))
            and a.sarappd_apdc_date = (select max(b.sarappd_apdc_date)
                                       from sarappd b
                                       where 1 = 1
                                       and b.sarappd_apdc_date       < l_embargo_start_date
                                       -- ADM Nov 2016 Offer Letter changes - START
                                       and b.sarappd_apdc_code        in ('C','CD','CF','CI','U','UF','UD','UI','UP','R','W')--('C','CD','CF','CI','U','UF','UD','UI','UP')
                                       -- ADM Nov 2016 Offer Letter changes - END
                                       and b.sarappd_term_code_entry = a.sarappd_term_code_entry
                                       and b.sarappd_appl_no         = a.sarappd_appl_no                         
                                       and b.sarappd_pidm            = a.sarappd_pidm) 
            and a.sarappd_apdc_date       < l_embargo_start_date
            -- ADM Nov 2016 Offer Letter changes - START
            and a.sarappd_apdc_code        in ('C','CD','CF','CI','U','UF','UD','UI','UP','R','W') --('C','CD','CF','CI','U','UF','UD','UI','UP')
            -- ADM Nov 2016 Offer Letter changes - END
            and a.sarappd_term_code_entry = l_term_code_entry
            and a.sarappd_appl_no         = l_appno                       
            and a.sarappd_pidm            = l_pidm),'~')   l_C_Decision  
       ,(select c.skrudec_decn_seq --c.rowid --c.skrudec_off_lib_string
             from skrudec  c
                 ,skrudap
                 ,sarappd  a
             where 1 = 1
             and c.skrudec_decn_seq        = (select max(d.skrudec_decn_seq)
                                              from skrudec d
                                              where 1 = 1
                                              and d.skrudec_off_lib_string  is not null
                                              and d.skrudec_choice_type_no  = c.skrudec_choice_type_no
                                              and d.skrudec_pidm            = c.skrudec_pidm)
             and c.skrudec_choice_type_no  = skrudap_choice_no
             and c.skrudec_pidm            = skrudap_pidm  
             and skrudap_term_code_entry   = a.sarappd_term_code_entry
             and skrudap_appl_no           = a.sarappd_appl_no  
             and skrudap_pidm              = a.sarappd_pidm
             and a.sarappd_seq_no          = (select max(b.sarappd_seq_no)
                                              from sarappd b
                                              where 1 = 1
                                              and b.sarappd_apdc_date       < l_embargo_start_date
                                              and b.sarappd_apdc_code        in ('C','CD','CF','CI')
                                              and b.sarappd_term_code_entry  = a.sarappd_term_code_entry
                                              and b.sarappd_appl_no          = a.sarappd_appl_no                         
                                              and b.sarappd_pidm             = a.sarappd_pidm
                                              and trunc(b.sarappd_apdc_date) = trunc(a.sarappd_apdc_date))
            and a.sarappd_apdc_date         = (select max(b.sarappd_apdc_date)
                                              from sarappd b
                                              where 1 = 1
                                              and b.sarappd_apdc_date       < l_embargo_start_date
                                              and b.sarappd_apdc_code        in ('C','CD','CF','CI')
                                              and b.sarappd_term_code_entry = a.sarappd_term_code_entry
                                              and b.sarappd_appl_no         = a.sarappd_appl_no
                                              and b.sarappd_pidm             = a.sarappd_pidm)
           and a.sarappd_apdc_date       < l_embargo_start_date                                   
           and a.sarappd_apdc_code        in ('C','CD','CF','CI')
           and a.sarappd_term_code_entry = l_term_code_entry
           and a.sarappd_appl_no         = l_appno                        
           and a.sarappd_pidm            = l_pidm)  offer_string                             
from  dual
where p_earlier = 'Y';


function mdx_get_status_f     (p_pidm               in number 
                              ,p_aidm               in number
                              ,p_application_type   in varchar2 default null
                              ,p_source_query       in varchar2 default null
                              ,p_status             in varchar2 default null
                              ,p_appno              in varchar2 default null
                              ,p_term_code          in varchar2 default null
                              ,p_decision_code      in varchar2 default null
                              ,p_UF_Decision         in varchar2 default null
                              ,p_C_Decision         in varchar2 default null
                              ,p_saradap_admt_code  in varchar2 default null
                              ,p_skrsain_source     in varchar2 default null
                              ,p_offer              in number default null)
return varchar2 as
--
l_string               varchar2(1000);
l_status_decision_code varchar2(5);
l_return               varchar2(2000);
l_url                  varchar2(1000);
l_need_ucas_link       skvssdt.skvssdt_data%type;
l_action               varchar2(1000);
--
begin
-- ADM Nov 2016 Offer Letter changes - START
-- altered p_c_decision - the field now includes U,UF,UD,UI,UP as that is the real decision and we need to display that status always
-- note that we no longer need to return a link so can just return the string - if am offer letter exists the main My Applications list for status will 
-- ADM Nov 2016 Offer Letter changes - END

  if nvl(p_C_Decision,'~') = '~' then
    
     l_status_decision_code := p_decision_code;
  else
     l_status_decision_code := p_C_Decision;     
  end if;
    
-- note will never call this function if an online application that is incomplete or submitted but not pushed

           select nvl((select trim(skvssdt_short_title)
                       from skvssdt
                       where 1 = 1
                       and   skvssdt_sdat_code_opt_1  = l_status_decision_code
                       and   skvssdt_eff_date         <= sysdate
                       and   skvssdt_status_ind       = 'A'
                       and   skvssdt_sdat_code_attr   = 'MY_APPLICATION_STATUS'
                       and   skvssdt_sdat_code_entity = 'ONLINEAP'),'~')
                    ,nvl((select trim(SKVSSDT_DATA)
                       from skvssdt
                       where 1 = 1
                       and   skvssdt_sdat_code_opt_1  = l_status_decision_code
                       and   skvssdt_eff_date         <= sysdate
                       and   skvssdt_status_ind       = 'A'
                       and   skvssdt_sdat_code_attr   = 'MY_APPLICATION_STATUS'
                       and   skvssdt_sdat_code_entity = 'ONLINEAP'),'~')
                     ,nvl((select trim(SKVSSDT_title)
                       from skvssdt
                       where 1 = 1
                       and   skvssdt_sdat_code_opt_1  = l_status_decision_code
                       and   skvssdt_eff_date         <= sysdate
                       and   skvssdt_status_ind       = 'A'
                       and   skvssdt_sdat_code_attr   = 'MY_APPLICATION_STATUS'
                       and   skvssdt_sdat_code_entity = 'ONLINEAP'),'~')
           into  l_string
                ,l_need_ucas_link
                ,l_action
           from dual;

   
-- ADM Nov 2016 Offer Letter changes - START
/*
if (l_status_decision_code in ('C','CD','CF','CI') or l_need_ucas_link = 'TRACK_LINK')
         then

      if p_skrsain_source = 'D' 
           then
           
           -- ADM Sept 2016 for agent portal we are disabling the Conditions of Offer pop-up link as this will be superseded when we do the Offer Letters functionality
          
            -- l_return:= l_string;
--              if p_offer is not null then
              
    --            l_return := '<a href="bwskalog.mdx_applicant_offer_p?appno='||p_appno||'&p_offer='||p_offer||'" target ="_blank" style="color:red">'||l_string||'</a>';
              
    --          else
                  l_return:= l_string;
  --            end if;
-- mdx adm start July 2016                   
--         elsif p_saradap_admt_code = '9' and p_skrsain_source = 'U'
         elsif p_skrsain_source = 'U'
-- mdx adm end July 2016
            then
                 
              select trim(skvssdt_title)
              into l_url
              from skvssdt
              where 1 = 1
              and   skvssdt_sdat_code_opt_1  = 'U'
              and   skvssdt_eff_date         <= sysdate
              and   skvssdt_status_ind       = 'A'
              and   skvssdt_sdat_code_attr   = 'APPLY_URL'
              and   skvssdt_sdat_code_entity = 'ONLINEAP';                     

           -- l_return := '<a href="'||l_url||'" target="_blank">'||l_string||'</a>';  
          --l_return := '<a href="'||l_url||'" target="_blank" style="color:red">'||l_string||'</a>';      

              -- Agents should not get the UCAS links   
              l_return := l_string;

-- mdx adm start July 2016                   
--          elsif p_saradap_admt_code = '9' and p_skrsain_source = 'G'
         elsif p_skrsain_source = 'G'
-- mdx adm end July 2016

            then

              select trim(skvssdt_title)
              into l_url
              from skvssdt
              where 1 = 1
              and   skvssdt_sdat_code_opt_1  = 'G'
              and   skvssdt_eff_date         <= sysdate
              and   skvssdt_status_ind       = 'A'
              and   skvssdt_sdat_code_attr   = 'APPLY_URL'
              and   skvssdt_sdat_code_entity = 'ONLINEAP';     

              -- ADM Nov 2016 Offer Letter changes - END
              
            --  l_return := '<a href="'||l_url||'" target="_blank">'||l_string||'</a>';  
            
            --l_return := '<a href="'||l_url||'" target="_blank" style="color:red">'||l_string||'</a>';   
              
            -- Agents should not get the UCAS links   
              l_return := l_string;
              
          end if;
      else 
             if l_string = '~' then
                l_string := null;
             else   
               l_return := l_string;              
             end if;

    end if; */

             if l_string = '~' then
                l_string := null;
             else   
               l_return := l_string;              
             end if;

-- ADM Nov 2016 Offer Letter changes - END
  
return (nvl(l_return,'Contact us'));

end mdx_get_status_f;


function mdx_get_my_actions_f (p_pidm               in number 
                              ,p_aidm               in number
                              ,p_application_type   in varchar2 default null
                              ,p_source_query       in varchar2 default null
                              ,p_status             in varchar2 default null
                              ,p_appno              in varchar2 default null
                              ,p_term_code          in varchar2 default null
                              ,p_decision_code      in varchar2 default null
                              ,p_saradap_admt_code  in varchar2 default null
                              ,p_skrsain_source     in varchar2 default null
                              ,p_profressonial_checks in varchar2 default null)
return varchar2 as

-- p_application_type
-- OA  = online application
-- NOA = non-online application

-- p_source_query
-- I = incomplete online application
-- S = submitted online application that still needs to be deduped and pushed
-- P = pushed online application
-- O = all others including UCAS, GTTR, direct non Online Application, etc

l_string     varchar2(1000);
l_return     varchar2(1000);
l_my_action  varchar2(1000);
l_accept_url varchar2(1000);

begin
   -- online application that is incomplete
   if (nvl(p_application_type,'~') = 'OA' 
       and NVL(p_source_query,'~')   = 'I') 
       then 
          l_string := 'Resume';--'<a href="bwskalog.p_dispindex?appno='||p_appno||'" target="_blank" style="color:red">Resume </a>'; 
          --'<a href="bwskalog.p_dispindex?appno='||p_appno||'" style="color:red">Resume </a>';
          
    -- online application is has been submitted but not yet pushed/deduped
    elsif (nvl(p_application_type,'~') = 'OA' 
           and NVL(p_source_query,'~')   = 'S')
           then
           
           l_string := 'No action required - Awaiting university attention' ;

    else
           select nvl((select trim(skvssdt_title)
                       from skvssdt
                       where 1 = 1
                       and   skvssdt_sdat_code_opt_1  = p_decision_code
                       and   skvssdt_eff_date         <= sysdate
                       and   skvssdt_status_ind       = 'A'
                       and   skvssdt_sdat_code_attr   = 'MY_APPLICATION_STATUS'
                       and   skvssdt_sdat_code_entity = 'ONLINEAP'),'~')
           into  l_my_action
           from dual;        
           
    end if;
-- ADM Nov 2016 Offer Letter changes - START
/* no longer required as the link to the Offer page will be on the main index page
    if upper(l_my_action) = 'SUBMIT FURTHER INFORMATION' 
       then
         
             -- l_string:= '<a href="mdx_doc_upload_pkg.mdx_doc_request_p?pidm='||p_pidm||'&term_code='||p_term_code||'&appl_no='||p_appno||'" style="color:red">'||l_my_action||'</a>';
  
                l_string := l_my_action;
                
    elsif UPPER(l_my_action) = 'RESPOND TO OFFER'--'ACCEPT OFFER'
      then
         if p_skrsain_source = 'D' 
           then
          
              l_string := l_my_action||' - Please refer to offer letter';
               
-- mdx adm start July 2016                   
--         elsif p_saradap_admt_code = '9' and p_skrsain_source = 'U'
         elsif p_skrsain_source = 'U'
-- mdx adm end July 2016

            then
            
           
              select trim(skvssdt_title)
              into l_accept_url
              from skvssdt
              where 1 = 1
              and   skvssdt_sdat_code_opt_1  = 'U'
              and   skvssdt_eff_date         <= sysdate
              and   skvssdt_status_ind       = 'A'
              and   skvssdt_sdat_code_attr   = 'APPLY_URL'
              and   skvssdt_sdat_code_entity = 'ONLINEAP';             
               
           --  <a href="http://www.w3schools.com/" target="_blank"><href="http://www.mdx.ac.uk" target="_blank">Visit W3Schools!</a>
            
              --l_string := '<a href="'||l_accept_url||'" target="_blank" style="color:red">'||l_my_action||'</a>';                
                
              -- Agents should not be directed to the UCAS Links  
              l_string := l_my_actions;
              
-- mdx adm start July 2016                   
--          elsif p_saradap_admt_code = '9' and p_skrsain_source = 'G'
         elsif p_skrsain_source = 'G'
-- mdx adm end July 2016

            then
            
              select trim(skvssdt_title)
              into l_accept_url
              from skvssdt
              where 1 = 1
              and   skvssdt_sdat_code_opt_1  = 'G'
              and   skvssdt_eff_date         <= sysdate
              and   skvssdt_status_ind       = 'A'
              and   skvssdt_sdat_code_attr   = 'APPLY_URL'
              and   skvssdt_sdat_code_entity = 'ONLINEAP';     

              --l_string := '<a href="'||l_accept_url||'" target="_blank" style="color:red">'||l_my_action||'</a>';       
 
              -- Agents should not be directed to the UCAS Links  
              l_string := l_my_actions;
 
          end if;
          
     end if; 
*/
-- ADM Nov 2016 Offer Letter changes - END
    l_return := nvl(l_string,l_my_action);
    
    return nvl(l_return,'Contact us');  
    
end mdx_get_my_actions_f;

-- mdx adm end Oct 2015

   BEGIN
   
      -- check the security is ok to access page
    /*  aidm := bwskalog.f_checksecurity (appno);

      IF aidm = 0
      THEN
         RETURN;
      END IF;

      --
      IF bwskalog.exit_flag = 'TRUE'
      THEN
--         bwskalog.msg.text := 'EXIT FLAG';
         RETURN;
      END IF;
      
      IF bwskalog.msg.text IS NOT NULL
      THEN
         cell_msg_flag := 'Y';
         bwskalog.P_PrintMsg;
      END IF;  
      
    if not twbkwbis.F_Validuser(pidm) then
      return;
     end if;    */
     
    open get_ucas_embargo_dates_c;
    -- mdx adm start July 2016 
    -- so I do not have to alter the decision/action sql
    -- for creating the date+time swapped over to using an org varible for the to hold the gtvsdax entry
    fetch get_ucas_embargo_dates_c into l_embargo_org_start_date
                                       ,l_embargo_start_time
                                       ,l_embargo_org_end_date
                                       ,l_embargo_end_time;
    close get_ucas_embargo_dates_c;
    -- -- mdx adm end July 2016
    
    if (l_embargo_org_start_date is null
        and l_embargo_org_end_date is null)
        then
          l_embargo_active := 'N';
    end if;
    
    --l_con_start_date := trunc(l_embargo_start_date)||' 12:00';
    --l_con_end_date   := trunc(l_embargo_end_date)||' 17:00';
    
   -- mdx adm start July 2016
     
    --trunc(l_embargo_org_start_date)+substr(l_embargo_start_time,1,2)/24 + substr(l_embargo_start_time,3,2)/1400;
    -- DATE                           HOURS                   MINUTES
    /*select to_char(trunc(sysdate)+substr('1000',1,2)/24 + substr(1024,3,2)/1400,'DD-MON-YYYY hh24:mi')
      from dual
      returns
      08-JUL-2016 10:24
    */
    
     l_embargo_start_date := trunc(l_embargo_org_start_date)+substr(l_embargo_start_time,1,2)/24 + substr(l_embargo_start_time,3,2)/1400;
     l_embargo_end_date   := trunc(l_embargo_org_end_date)+substr(l_embargo_end_time,1,2)/24 + substr(l_embargo_end_time,3,2)/1400;
   
   -- need to double check the decision selection workds correctly with the time element added
   
 
    
--   if trunc(sysdate) between l_embargo_start_date and l_embargo_end_date
 --   if  sysdate between to_date(l_con_start_date,'dd-MON-yyyy HH:MI') AND to_date(l_con_end_date,'dd-MON-yyyy HH:MI')
  if sysdate between l_embargo_start_date and l_embargo_end_date  -- removing the trunc(sysdate) means it will look at the time element of the embargo dates
      then
        l_embargo_active := 'Y';
    end if;
    
    -- need to check if the cursor finding the decision also looks at the time element - date part it will but not sure of the time

   open get_agent_details_c;
   fetch get_agent_details_c into l_agency_name
                                 ,l_agency_code
                                 ,l_agent_seq
                                 ,l_agent_id
                                 ,l_agent_type
                                 ,l_agent_name
                                 ,l_agent_view_all
                                 ,l_agent_view_group
                                 ,l_agent_view_own
                                 ,l_agent_group_a
                                 ,l_agent_group_b      
                                 ,l_agent_group_c   
                                 ,l_agent_group_d
                                 ,l_agent_active_ind
                                 ,l_regional_office_code;
   close get_agent_details_c;

  if nvl(l_agent_active_ind,'N') = 'N' 
     then
       
      twbkwbis.p_opendoc ('mdx_agent_portal_pkg.mdx_agent_applicant_list_p', exit_url => app_exit_url);    
      
      twbkfrmt.p_printheader(3, 
            '<font size=3 color = "red"><b>Manage my applications</b></font>');
       
       twbkwbis.p_dispinfo('mdx_agent_portal_pkg.mdx_agent_applicant_list_p','NOT_ACTIVE');

 
      twbkwbis.p_closedoc;
       
---      dbms_output.put_line ('You are not currently an active Agent'); 
       -- need to get from Jackie what I should display if they are not an active agent 
       -- use display info to hold the response
       
  else

   l_agency_codes_all := ''''||l_agency_code||'''';
   
   if l_agent_view_all = 'Y'
      then
         l_view := 'ALL';
   elsif l_agent_view_own = 'Y'
       then
          l_view := 'OWN';
   elsif l_agent_group_a = 'Y'
        then
          l_view := 'GROUP';
   elsif l_agent_group_b = 'Y'
        then
          l_view := 'GROUP';
   elsif l_agent_group_c = 'Y'
        then
          l_view := 'GROUP';
   elsif l_agent_group_d = 'Y'
        then
          l_view := 'GROUP';                   
   end if;  
   
     if (l_agent_type = 'DIR' and nvl(l_agent_view_all,'N') = 'Y') then
   
         open get_agent_secondary_details_c;
         loop
         fetch get_agent_secondary_details_c into l_agency_code_sec;
         exit when get_agent_secondary_details_c%notfound;
         
         if get_agent_secondary_details_c%found then
             l_agency_codes_all    := l_agency_codes_all||','''||l_agency_code_sec||'''';
         end if;
          
         l_agency_code_sec := null;
         
         end loop;
         
         close get_agent_secondary_details_c;
         
      end if;
   
      twbkwbis.p_opendoc ('mdx_agent_portal_pkg.mdx_agent_applicant_list_p', exit_url => app_exit_url);

--htp.p('<style type="text/css">
htp.style('  

TABLE.dataentrytable {
  background-color:#efefef;
border-left: 1px black solid;

border-right: 1px black solid;

  padding:20px;
  margin-top: 20px;

  border-radius: 5px;
  border-collapse:collapse;
  text-align: center;
}
table.dataentrytable tr {
  border-bottom: inset #ccc 1px;
}

table.dataentrytable td {
  border-left: 1px #ccc inset;
  
}

table.dataentrytable tr:nth-child(odd) {

  background-color: #fff;

  
}
table.dataentrytable td.dedefault input[type=submit] {
   font-size:small;
   margin: 5px 5px 5px 0;
  border-radius: 5px;
  padding:2px;
  font-weight:normal;


}

table.dataentrytable td.dedefault form input[type=submit] {
  font-size:small;
  margin: 5px 5px 5px 0;
  border-radius: 5px;
  padding:2px;
  font-weight:normal;
}
  input[type=button] {
  //background: #ff00ff;
  background-image: -webkit-linear-gradient(top, #ff0000, #b82b2b);
  background-image: -moz-linear-gradient(top, #ff0000, #b82b2b);
  background-image: -ms-linear-gradient(top, #ff0000, #b82b2b);
  background-image: -o-linear-gradient(top, #ff0000, #b82b2b);
  background-image: linear-gradient(to bottom, #ff0000, #b82b2b);
  color:white;
  border-bottom-right-radius:10px;
  border-top-left-radius:10px;
  padding:4px;
  font-weight:bold;
  font-size:medium;

  font-family:dax,tahoma,verdana,helvetica,sans-serif;
}

input[type=button]:hover {
  background: #bd1111;
  background-image: -webkit-linear-gradient(top, #bd1111, #ff0000);
  background-image: -moz-linear-gradient(top, #bd1111, #ff0000);
  background-image: -ms-linear-gradient(top, #bd1111, #ff0000);
  background-image: -o-linear-gradient(top, #bd1111, #ff0000);
  background-image: linear-gradient(to bottom, #bd1111, #ff0000);
  text-decoration:underline;
}');
--</style>');

-- PG NOV 2017 START


htp.style(
'.rowInvisible
{
  display:none;

}

.textInput {

  background-position: 0px 0px;
  background-size:15px;
  background-repeat: no-repeat;
  border-radius:10px;
  padding-left:20px;
  width:100px;
  font-size:80%;
  height:15px;
}
hr {
margin: 5px;
}

select {
  height:22px;
  font-size:80%;
  width:145px;
}

.ico-mglass {
  position:relative;
  display:block;
  background: #fff;
  border-radius: 30px;
  height: 6px;
  width: 6px;
  border: 2px solid #888;
  top: -16px;
  left: 5px;
}
.ico-mglass:after {
    content: "";
    height: 2px;
    width: 6px;
    background: #888;
    position:absolute;
    top:7px;
    left:5px;
    -webkit-transform: rotate(45deg);
    -moz-transform: rotate(45deg);
    -ms-transform: rotate(45deg);
    -o-transform: rotate(45deg);
  }
  .ico-mglass1 {
    position:relative;
    display:block;
    background: #fff;
    border-radius: 30px;
    height: 6px;
    width: 6px;
    border: 2px solid #888;
    top: -1px;
    left: -139px;
  }

  .ico-mglass1:after {
    content: "";
    height: 2px;
    width: 6px;
    background: #888;
    position:absolute;
    top:7px;
    left:5px;
    -webkit-transform: rotate(45deg);
    -moz-transform: rotate(45deg);
    -ms-transform: rotate(45deg);
    -o-transform: rotate(45deg);
}

.close {
  display:block;
  position: relative;
  left:97px;
  top:-25px;
  width: 5px;
  height: 5px;
  opacity: 0.3;
  text-align: right;

}
.close:hover {
  opacity: 1;
}
.close:before, .close:after {
  position: absolute;
  left: 15px;
  content: " ";
  height: 10px;
  width: 2px;
  background-color: #333;
}
.close:before {
  transform: rotate(45deg);
}
.close:after {
  transform: rotate(-45deg);
}
input[autocomplete="off"]::-webkit-contacts-auto-fill-button {
  visibility: hidden;
  display: none !important;
  pointer-events: none;
  height: 0;
  width: 0;
  margin: 0;
}
.title {
    width: 3em;
    margin-top: 0;
}
.dob {
    margin-top: 0;
    width: 7em;
}');
htp.script('
function getTableAndRows() {

    // Quick function to get the rows from a given table.
    // Saves doing this in every function in this code...

    var table,tr;

    table = document.getElementById("mainTable");
    tr = table.getElementsByTagName("tr");

    return (table,tr);
}

function setupSelect(column) {

//This code will get all the distinct data in a column in a given table.
// and create a select in the header so it can be searched on it.


// Update July 2017 to fix bug that caused intermittent issues
// with selects not being created.

// Use a Regular Expression to find any text on Buttons with forms that
// the regular text search is missing.
// trim and whip out any non breaking spaces that stop the non button text
// matching with the button text.
// Regular Expression also has to account for the fact that different browsers
// render the buttons differently Firefox and chrome reverse the syntax of the
// HTML.

// PG -- July 2017

    var searchColumn = "select" + column;

    var targetSelect = document.getElementById(searchColumn);
    var table,tr = getTableAndRows();
    var uniqueElements = {};
    var option = document.createElement("option");


    var td;
    for (i=1; i< tr.length; i++) {
        td = tr[i].getElementsByTagName("td")[column];
        var tdHTML = td.innerHTML.split("&nbsp"); // remove any trailing non breaking spaces.
        if (tdHTML[0].includes("<form")){
            var myregex = /(\<input value=\"|\<input type=\"submit\" value=\")(.*?)(\"\s+type=\"submit|\"\>\s+)/i; // upgated regex for crossbrowser support.
            uniqueElements[tdHTML[0].match(myregex)[2].trim()] = "x";
        } else {

            uniqueElements[tdHTML[0].trim()] = "x"; // normal text
        }
    }

    option = document.createElement("option");
    option.text = "All";
    option.value="";
    targetSelect.add(option);
    //Object.keys(uniqueElements).sort().forEach(function(key){
   for (var key in uniqueElements) {


  option = document.createElement("option");
   var tmp = key.split("&nbsp"); // drop non breaking spaces
   console.log(tmp[0]);
   if (tmp[0].includes("<form")){
       alert(tmp[0]);
       //var myregex = /\<input\ value\=\"(.*?)\"\s+type\=\"submit/i;  // button text
       var myregex = /(\<input value=\"|\<input type=\"submit\" value=\")(.*?)(\"\s+type=\"submit|\"\>\s+)/i; // updated regex for crossbrowser support.
       var myresult = myregex.exec(tmp[0]);
       
      // option.text=tmp[0].match(myregex)[2]; // the [2] gets the bit the brackets within the Regex... otherwise you match the whole thing which is not what we want here
       //option.value=tmp[0].match(myregex)[2];
   } else {
       option.text = tmp[0];
       option.value= tmp[0];


   }
         targetSelect.add(option);
   }

    document.getElementById(searchColumn).classList.remove("rowInvisible");
    document.getElementById(searchColumn).setAttribute("onchange","selectSearch(" + column+ ")");
}


function selectSearch(column) {

    // To trigger a search using a select drop down we have to copy the selected item
    // into a hidden text field and then trigger a standard search.

    var searchColumn = "select" + column;
    var searchField = document.getElementById(searchColumn);
    var searchTerm = searchField.options[searchField.selectedIndex].value;

    document.getElementById(column).value = searchTerm;

    getSearches();

}

function searchFunction(searchText,column) {

    // Main search funtion -- goes through every row in a column looking
    // for the required text.

    var rows = [0];


  var input, filter, table, tr, td, i,foundRows = [];
  input = document.getElementById(column);
  filter = input.value.toUpperCase();

  table,tr = getTableAndRows();

  for (i = 0; i < tr.length; i++) {
    td = tr[i].getElementsByTagName("td")[column];
    if (td) {

      // Following is needed for the select/option where conditional search was picking up unconditionals
      // this trims down the search and ensures that this field checks only for an exact search
      // BUT only for this column.
      // PG -- July 2017

   if (column === 7) {
        var newregex = new RegExp(input.value);

        if (td.innerHTML.match(newregex)) {

        //if (td.innerHTML.split("&nbsp")[0].toUpperCase().trim() == filter.trim()) {
        foundRows.push(i);
        }
      } else {
      if (td.innerHTML.toUpperCase().indexOf(filter) > -1) {
                 if (filter !== ""){
                    foundRows.push(i);
                }

      }
    }

    }
  }

  if (filter === ""){

      return null ;
  } else {
  return foundRows;
  }
}


function resetTable() {

    // Reset function -- makes everything visible again so new searches can start afresh.

    var inputs = document.getElementsByClassName("textInput");


    var table,tr = getTableAndRows();

    for(i = 1; i< tr.length ;i++) {

        tr[i].classList.remove("rowInvisible");
        tr[i].style.backgroundColor = "";
    }

}

function clearField (column) {
    //This clears the fiels of text when the little "x" is clicked"
    //PG July 2017
    document.getElementById(column).value="";
    getSearches();

}
function getSearches() {

    // Reset the table -- show all the rows and reset the search parameters

    resetTable();

    // Find all the columns and which ones are not empty

    var inputs = document.getElementsByClassName("textInput");
    var combText = "";
    for (j = 0; j < inputs.length; j ++) {
        combText = combText + inputs[j].value;
    }

    if (combText === "" ) {

        return 0;
    }

    var results = [];
    var intersected =[];
    var tableRows = {};
    var mySearches = document.getElementsByClassName("textInput");


    for (i = 0; i < mySearches.length; i++) {

     // do a search....

    results = searchFunction(i,i);

    if (results === null) {
        // If any fields are blank ignore them so they dont affect the search results

        } else {

    intersected.push(results);
    }

    }

    var table,tr = getTableAndRows();

    // This is the clever bit -- merging the arrays into one and returning only the rows that are the same in each!
    // Slightly dumbed down version so IE can cope.

    var result = intersected.shift().filter(function(v) {
    return intersected.every(function(a) {
        return a.indexOf(v) !== -1;
        });
    });

    result.forEach(function(row){

        tableRows[row] ="x";
    });


     var colourCount = 0;
    for (var k = 1; k < tr.length; k++) {

        if (!tableRows[k]) {
           tr[k].classList.add("rowInvisible");
        } else {
             tr[k].classList.remove("rowInvisible");
                colourCount++;
            /*
                Using a simple counter and modulo arithmetic we put back the
                alternating colours when the searches are complete to give the grid effect.
                PG -- July 2017
            */
                if (colourCount % 2 == 0){
             tr[k].style.backgroundColor="white";
                } else {
                    tr[k].style.backgroundColor="#eee";
                }
        }
    }

}
 window.onload = function () {

        // This function sets up the search form when the page loads.


        // First Add an ID attribute to the table so that everything that comes afterwards
        // can work.

        var getmainTable =  document.getElementsByClassName("dataentrytable");
        for ( var i = 0; i < getmainTable.length; i++) {
            getmainTable[i].setAttribute("id","mainTable");
        }

        // The following JSON object contains the hardcoded HTML for every column -- this will need to be updated if
        // and when the table ever changes there is no real choice here as no easy way to get this info into the javascript
        // programatically.

        // The underscores are spacers to align the search windows where there is only one line of text in the header row.



        // REMEMBER -- NB!!!! -- Escape ALL Inverted commas within the html or the page will fail !!!
if (!String.prototype.includes) {
     String.prototype.includes = function() {
        
         return String.prototype.indexOf.apply(this, arguments) !== -1;
     };
 }
 

    var searchFieldSetup = {
"0": {
  "html": "<hr /><input type=\"text\" autocomplete=\"off\" onkeyup=\"getSearches()\" class=\"textInput\" id=\"0\"><span class=\"ico ico-mglass\"></span></span><span class=\"close\" onclick=clearField(\"0\")></span>"
},
"1": {
  "html": "<input type=\"text\" class=\"textInput rowInvisible\" id=\"1\">"
},
"2": {
  "html": "<hr /><input type=\"text\" autocomplete=\"off\" onkeyup=\"getSearches()\" class=\"textInput\" id=\"2\"><span class=\"ico ico-mglass\"></span></span><span class=\"close\" onclick=clearField(\"2\")></span>"
},
"3": {
  "html": "<hr /><input type=\"text\" autocomplete=\"off\" onkeyup=\"getSearches()\" class=\"textInput\" id=\"3\"><span class=\"ico ico-mglass\"></span></span><span class=\"close\" onclick=clearField(\"3\")></span>"
},
"4": {
  "html": "<input type=\"text\" class=\"textInput rowInvisible\" id=\"4\">"
},
"5": {
  "html": "<div style=\"color:#E3E5EE\">______</div><hr /><input type=\"text\" autocomplete=\"off\" onkeyup=\"getSearches()\"class=\"textInput\" id=\"5\"><span class=\"ico ico-mglass\"></span></span><span class=\"close\" onclick=clearField(\"5\")></span>"
},
"6": {
  "html": "<hr /><input type=\"text\" class=\"textInput rowInvisible\" id=\"6\"><select id =\"select6\" class=\"rowInvisible\">"
},
"7": {
  "html": "<div style=\"color:#E3E5EE\">______</div><hr /><input type=\"text\" class=\"textInput rowInvisible\" id=\"7\"><select id =\"select7\"  class=\"rowInvisible\">"
},
"8": {
  "html": "<div style=\"color:#E3E5EE\">______</div><hr /><input type=\"text\" class=\"textInput rowInvisible\" id=\"8\"><select id =\"select8\"  class=\"rowInvisible\">"
},
"9": {
  "html": "<div style=\"color:#E3E5EE\">______</div><hr /><input type=\"text\" autocomplete=\"off\" onkeyup=\"getSearches()\" class=\"textInput\" id=\"9\"><span class=\"ico ico-mglass\"></span><span class=\"close\" onclick=clearField(\"9\")></span>"
}
};


    var tableHeaders = document.getElementsByClassName("deheader");




    for (var k=0; k <tableHeaders.length; k++) {

      tableHeaders[k].innerHTML = tableHeaders[k].innerHTML + searchFieldSetup[k].html;
    }



    // Fill up the drop down menus with the needed data ...

    setupSelect(6); // Column 6
    setupSelect(7); // Column 7
    setupSelect(8); // Column 8 

// Below is the inline style
// For the modifications introducec by this javascript.
// So we do not have to update the overall style sheet.
}');
 
 -- PG NOV 2017 END


      l_query := 'null';
/* Removed this as this is causing pages to slow JMP 20 Oct 2016 */
      -- CHECK THERE IS AT LEAST ONE ACTIVE APPLICATON      
      --open get_details_exist;
      --fetch get_details_exist into  l_query; 
      --close get_details_exist;
              
       if l_query is null 
            then
            twbkfrmt.p_printheader(3, 
            '<font size=3 color = "red"><b>Manage my applications</b></font>');
                --  htp.p('<br></br>');
                  twbkwbis.p_dispinfo('mdx_agent_portal_pkg.mdx_agent_applicant_list_p','NOAPPLMSG');
                --  htp.p('<br>');   

-- remove when course search page available start
/*          twbkfrmt.p_tableopen ('DATAENTRY',
                           cattributes => G$_NLS.Get ( 'bwskalog-MDX0001',
									                                     'SQL',
                                                       'summary="This table displays all current applications."'));

       twbkfrmt.p_tablerowopen;
      twbkfrmt.p_tabledata (
         twbkfrmt.f_printanchor (
            twbkfrmt.f_encodeurl (
               twbkwbis.f_cgibin || 'mdx_course_search_pkg.mdx_disp_search_page_p'
            ),
            g$_nls.get ('BWSKALO1-0054', 'SQL', 'New')
         )
      );
      twbkfrmt.p_tabledata (
         g$_nls.get ('BWSKALO1-0055', 'SQL', 'Create a new application'),
         ccolspan   => '4'
      );
      twbkfrmt.p_tablerowclose; 
      twbkfrmt.p_tableclose;*/


/*       twbkfrmt.p_tablerowopen;
      twbkfrmt.p_tabledata (
         twbkfrmt.f_printanchor (
            twbkfrmt.f_encodeurl (
               twbkwbis.f_cgibin || 'bwskalog.P_SelNewApp' ||
                  '?wapp=&noapps=&in_secured=' ||
                  in_secured
            ),
            g$_nls.get ('BWSKALO1-0054', 'SQL', 'New')
         )
      );
      twbkfrmt.p_tabledata (
         g$_nls.get ('BWSKALO1-0055', 'SQL', 'Create a new application'),
         ccolspan   => '4'
      );
      twbkfrmt.p_tablerowclose; */
      twbkfrmt.p_tableclose;
 
          
          twbkfrmt.p_tableclose;   
          HTP.br;  

-- remove when course search page available end
                
       else
       
       -- null the variables used to check at least one application existed 
          l_pidm                   := null;
          l_appno                  := null;         
          L_term_code_entry        := null;
          l_sarhead_appl_comp_ind  := null;
          l_sarhead_process_ind    := null;
          l_sarhead_wapp_code      := null;
          l_application_type       := null;
          l_query                  := null;
          l_program                := null;
          l_prog_desc              := null;
          l_term_desc              := null;
          l_status                 := null;
          l_app_created            := null;
          l_skrsain_source         := null;
          l_saradap_admt_code      := null;
          l_last_updated           := null;
          l_professional_checks    := null;
          l_display_prof_check_link := null;
          l_student_id             := null;
          l_last_name              := null;
          l_first_name             := null;
          l_middle_name            := null;
          l_birth_date             := null;
          l_name_prefix            := null;
          l_resd_desc              := null;
          l_aidm                   := null;
          l_skrsain_applicant_no   := null;
          l_applicant_agent_name   := null;
 
           twbkfrmt.p_printheader(3, 
            '<font size=3 color = "red"><b>Manage my Applications</b></font>');
            
            
          if l_embargo_active = 'Y' then
          
            twbkwbis.p_dispinfo ('mdx_agent_portal_pkg.mdx_agent_applicant_list_p', 'EMBARGO');  
          
          end if;
            

          twbkwbis.p_dispinfo ('mdx_agent_portal_pkg.mdx_agent_applicant_list_p');    
 
          -- htp.p('<form> <input TYPE="button" onclick="goBack()" value="Home"> </form>');
          -- htp.p('<input TYPE="button" onclick="goBack()" value="Home">');
 
 --          htp.p('<a href="#" onclick="history.go(-1)">Return to Homepage</a>');       
  htp.p('<form> <input TYPE="button" onclick="history.go(-1)" value="Return to Homepage"> </form>');         
            
  /*        htp.p('<br></br>');   
          htp.print('UCAS embargo start date = '||to_char(l_embargo_start_date,'DD-MON-YYYY hh24:mi'));
           htp.p('<br>');
          htp.print('UCAS embargo end date   = '||to_char(l_embargo_end_date,'DD-MON-YYYY HH24:MI'));
          htp.p('<br>');
          htp.print('UCAS embargo status     = '||l_embargo_active);                  
          htp.p('<br></br>');   
   */      
          twbkfrmt.p_tableopen ('DATAENTRY',
                           cattributes => G$_NLS.Get ( 'bwskalog-MDX0001',
									                                     'SQL',
                                                       'summary="This table displays all current applications."'));

           twbkfrmt.p_tablerowopen;
           
  /*          HTP.tableOpen ('border=1',
                             NULL,
                             NULL,
                             NULL,
                             NULL);
              HTP.tableRowOpen ('center',
                                NULL,
                                NULL,
                                NULL,
                                NULL);
  */                              

       --       twbkfrmt.p_tabledataheader (
        --         '<b>' || '  ' || '</b>'
        --      );

              twbkfrmt.p_tabledataheader (
                 '<b>' || 'Applicant<br>number &nbsp;&nbsp;' || '</b>'
              );

              twbkfrmt.p_tabledataheader (
                 '<p class="title"><b>' || 'Title &nbsp;&nbsp;' || '</b></p>'
              );

              twbkfrmt.p_tabledataheader (
                 '<b>' || 'First<br>name &nbsp;&nbsp;' || '</b>'
              );

              twbkfrmt.p_tabledataheader (
                 '<b>' || 'Family<br>name &nbsp;&nbsp;' || '</b>'
              );

              twbkfrmt.p_tabledataheader (
                 '<p class="dob"><b>' || 'Date of birth &nbsp;&nbsp;' || '</b></p>'
              );

       /*
              twbkfrmt.p_tabledataheader (
                 '<b>' || 'Country &nbsp;&nbsp;' || '</b>'
              );
      */

              twbkfrmt.p_tabledataheader (
                 '<b>' || 'Course &nbsp;&nbsp;' || '</b>'
              ); 

              twbkfrmt.p_tabledataheader (
                 '<b>' || 'Course &nbsp;&nbsp; <br>commencement &nbsp;&nbsp;' || '</b>'
              );

          /*    twbkfrmt.p_tabledataheader (
                 '<b>' || 'Application <br>created &nbsp;&nbsp;' || '</b>'
              );
              
              twbkfrmt.p_tabledataheader (
                 '<b>' || 'Last &nbsp;&nbsp; <br>updated &nbsp;&nbsp;' || '</b>'
              );
           */
              twbkfrmt.p_tabledataheader (
                 '<b>' || 'Status &nbsp;&nbsp;' || '</b>'
              );

              twbkfrmt.p_tabledataheader (
                 '<b>' || 'My actions' || '</b>'
              );

              twbkfrmt.p_tabledataheader (
                 '<b>' || 'Agency contact' || '</b>'
              ); 

   --           HTP.tableRowOpen;
              twbkfrmt.p_tablerowclose;
             
              open get_details_c;
              loop
                fetch get_details_c into  l_pidm 
                                         ,l_appno  -- not for pushed applications this is the saradap_appl_no so is different from the appno parameter online app pages use           
                                         ,l_term_code_entry 
                                         ,l_sarhead_appl_comp_ind 
                                         ,l_sarhead_process_ind
                                         ,l_sarhead_wapp_code
                                         ,l_application_type
                                         ,l_query
                                         ,l_program
                                         ,l_prog_desc
                                         ,l_term_desc
                                         ,l_status
                                         ,l_app_created
                                         ,l_skrsain_source
                                         ,l_saradap_admt_code 
                                         ,l_last_updated
                                         ,l_professional_checks
                                         ,l_student_id 
                                         ,l_last_name  
                                         ,l_first_name 
                                         ,l_middle_name
                                         ,l_birth_date
                                         ,l_name_prefix
                                        -- ,l_resd_desc   requirement removed after initial testing
                                         ,l_aidm
                                         ,l_skrsain_applicant_no
                                         ,l_applicant_agent_name;
               exit when get_details_c%notfound;

-- ADM AUG 2017 START
-- added to hide any UCAS application from the list of students if the embargo period is active
if (l_embargo_active = 'Y' and l_skrsain_source = 'U') then
       null;
else
-- ADM AUG 2017 END

-- login applicant to their account -  needed to open the Documents page
--   l_webid    := null;
--   l_web_pin  := null;
   
   open get_login_details_c;
   fetch get_login_details_c into  l_webid
                                  ,l_web_pin;
   close get_login_details_c;  
 
 
 -- 27-OCT-2016
 --  TO THE THIS LOCATION TO ALLOW THE L_OFFER TO BE PASSED TO THE DETAIL PAGE
                  if (l_embargo_active = 'N') 
                     then
                       
                       open   get_decision_details_c (p_current => 'Y'
                                                     ,p_earlier => 'N');
                       fetch  get_decision_details_c into l_decision_code   -- actual code
                                                         ,l_decision_date
                                                         ,l_UF_Decision     -- Y/N                       
                                                         ,l_C_Decision     -- actual code
                                                         ,l_offer;
                       close get_decision_details_c;
                       
                  elsif l_embargo_active = 'Y'  
                    then

-- mdx ADM July 2016 start
-- note the admt type can be changed to CR or DA for a UCAS applicant
                       if l_skrsain_source = 'U' then --and l_saradap_admt_code = '9' then
                         -- get earlier than embargo start date
-- mdx ADM July 2016 start
                          open   get_decision_details_c (p_current => 'N'
                                                        ,p_earlier => 'Y');
                          fetch  get_decision_details_c into l_decision_code   -- actual code
                                                            ,l_decision_date
                                                            ,l_UF_Decision     -- Y/N                       
                                                            ,l_C_Decision     -- actual code
                                                            ,l_offer;
                          close get_decision_details_c; 
                       else -- same as embargo not active
                     
                          open   get_decision_details_c (p_current => 'Y'
                                                        ,p_earlier => 'N');
                          fetch  get_decision_details_c into l_decision_code   -- actual code
                                                            ,l_decision_date
                                                            ,l_UF_Decision     -- Y/N                       
                                                            ,l_C_Decision     -- actual code
                                                            ,l_offer;
                          close get_decision_details_c; 
                      end if;                     
                  end if;
 
 
                -- ADM Nov 2016 Offer Letter changes - START
               if nvl(l_c_decision, '~') <> '~' then
               
                  select nvl((select distinct 'Y'
                              from MDX_OFFER_LETTER_LOG
                              where 1 = 1 --mdx_ofll_status     in ('PDF_GENERATED','EMAIL_SENT')
                              --and   nvl(MDX_OFLL_PDF_FILENAME,'~') <> '~'
                              and   mdx_ofll_status     in ('INITIAL'
                                                            ,'DATA_CHECK_FAILED'
                                                            ,'REQUESTED'
                                                            ,'REQUESTED_EVENING'
                                                            ,'HTML_EMAIL_GENERATED'
                                                            ,'HTML_GENERATED'
                                                            ,'HTML_FAILED'
                                                            ,'PDF_GENERATED'
                                                            ,'PDF_FAILED'
                                                            ,'EMAIL_NOT_REQUESTED'
                                                            ,'EMAIL_SENT'
                                                            ,'EMAIL_FAILED'
                                                            ,'EXCLUDED')
                              and   mdx_ofll_request_type <> 'DC'                              
                              and   MDX_OFLL_APPL_NO    = l_appno
                              and   MDX_OFLL_TERM_CODE  = l_term_code_entry
                              and   mdx_ofll_pidm       = l_pidm),'N')
                   into l_offer_letter_exists
                   from dual;
                           
               else               
                   l_offer_letter_exists := 'N';
              
               end if;
               -- ADM Nov 2016 Offer Letter changes - END    
        
               twbkfrmt.p_tablerowopen;

      -- NOTE Once the app_type is OAP - Online application pushed - these are the saradap values for appno and term_code_entry
 -- 3rd testing round - removed this condition as was causing an error when going to the detail page
 -- if the first application in the list was an online app submitted but not yet pushed
 -- if l_application_type||l_query <> 'OAI' then
  
     HTP.formopen ('mdx_agent_portal_pkg.mdx_agent_applicant_detail_p', 'post', '_blank');
  --    HTP.formopen ('mdx_agent_portal_pkg.mdx_agent_portal_piggyback_p', 'post', '_blank');
   --   HTP.formopen (twbkwbis.f_cgibin || 'bwskalog.P_ProcLoginNon', 'post','_blank');
 --      HTP.formopen ('mdx_agent_portal_pkg.mdx_agent_applicant_detail_p', 'post', '_blank');
--      twbkfrmt.P_FormHidden ('in_id',l_webid);
--      twbkfrmt.P_FormHidden ('pin',l_web_pin);    


      twbkfrmt.P_FormHidden ('p_xceduz','89KDFA7kjdJi368jSBo');
      twbkfrmt.P_FormHidden ('p_pidm',l_pidm);
      twbkfrmt.P_FormHidden ('p_aidm',l_aidm);
      twbkfrmt.P_FormHidden ('p_appno',l_appno); -- OA = sarahead_appl_seqno , NOA = saradap_appl_seqno
      twbkfrmt.P_FormHidden ('p_term_code_entry',l_term_code_entry);
      twbkfrmt.P_FormHidden ('p_skrsain_source',l_skrsain_source); 
      twbkfrmt.P_FormHidden ('p_skrsain_applicant_no',l_skrsain_applicant_no);
      twbkfrmt.P_FormHidden ('p_app_type',l_application_type||l_query); 
      twbkfrmt.P_FormHidden ('p_agent_id',l_agent_id); 
      twbkfrmt.P_FormHidden ('in_id',null);
      twbkfrmt.P_FormHidden ('pin',null); 

 /* else
  
      HTP.formopen (twbkwbis.f_cgibin || 'bwskalog.P_ProcLoginNon', 'post','_blank');
    --  htp.formHidden ('PAGE_ROUTE', 'AGENT_DOCUPLOAD');
      twbkfrmt.P_FormHidden ('in_id',l_webid);
      twbkfrmt.P_FormHidden ('pin',l_web_pin); 
      htp.formHidden ('NEWID', NULL);
      htp.formHidden ('NEWPIN', NULL);
      htp.formHidden ('VERIFYPIN', NULL);
      htp.formHidden ('SUBMIT_BTN', NULL);
      htp.formHidden ('p_appl_no', l_appno);
      htp.formHidden ('p_term_code',l_term_code_entry);  */
  
  
--  end if;
  
      /* NOTE  OAS = Online Application, Submitted -- but not yet loaded
               OAI = Online Application, Not completed
               OAP = Online Application, Pushed
               NOAO = Non online application, ie UCAS, GTTR etc
     */          

      
               -- view --
              --  twbkfrmt.p_tabledataopen; 
              -- HTP.print(l_student_id||'&nbsp;&nbsp;');
            --  htp.p('<input type="submit" value="View"/>');             
             --  twbkfrmt.p_tabledataclose;  
               
               -- Applicant number
               twbkfrmt.p_tabledataopen;
          --     htp.p('<input type="submit" value="View"/>');   
           --    HTP.print(l_student_id||'&nbsp;&nbsp;');
               if l_application_type||l_query IN ('OAI','OAS') -- online incomplete or online submitted but not yet pushed
                 then  
                     HTP.print(l_student_id||'&nbsp;&nbsp;');
                else
                    if length (l_student_id) < 10 then
                       twbkfrmt.P_FormHidden ('p_offer',l_offer); -- 27-OCT-2016
                       htp.p('<input type="submit" value="'||rpad(l_student_id,10)||'"/>'); 
                    else
                        twbkfrmt.P_FormHidden ('p_offer',l_offer); -- 27-OCT-2016
                        htp.p('<input type="submit" value="'||l_student_id||'"/>'); 
                    end if;
                    
--                    htp.formclose;              
                    
               end if;
  
              htp.formclose;   
  
               twbkfrmt.p_tabledataclose;              

               -- Title - name prefix
               twbkfrmt.p_tabledataopen; 
               HTP.print(l_name_prefix||'&nbsp;&nbsp;');
               twbkfrmt.p_tabledataclose;              


               -- First name
               twbkfrmt.p_tabledataopen; 
-- just used for when testing embargo hiding ucas apps
--               HTP.print('l_source'||l_skrsain_source||', '||l_first_name||'&nbsp;&nbsp;');
               HTP.print(l_first_name||'&nbsp;&nbsp;');
               twbkfrmt.p_tabledataclose;    
               
               -- Family name
               twbkfrmt.p_tabledataopen; 
               HTP.print(l_last_name||'&nbsp;&nbsp;');
               twbkfrmt.p_tabledataclose;                   

               -- Birth Date
               twbkfrmt.p_tabledataopen; 
               HTP.print(to_char(l_birth_date,'fxDD-MON-YYYY')||'&nbsp;&nbsp;');
               twbkfrmt.p_tabledataclose; 
 
/*                -- Country  country of residence
               twbkfrmt.p_tabledataopen; 
               HTP.print(l_resd_desc||'&nbsp;&nbsp;');
               twbkfrmt.p_tabledataclose;
*/            
               -- Course
               twbkfrmt.p_tabledataopen; 
               HTP.print(l_prog_desc||'&nbsp;&nbsp;');
               twbkfrmt.p_tabledataclose;
               
               -- Course commencement
               twbkfrmt.p_tabledataopen; 
               HTP.print(l_term_desc||'&nbsp;&nbsp;');
               twbkfrmt.p_tabledataclose;               

   /*            -- Application created
               twbkfrmt.p_tabledataopen; 
               HTP.print(to_char(l_app_created,'fxDD-MON-YYYY')||'&nbsp;&nbsp;');
               twbkfrmt.p_tabledataclose; */
               
/* 
-- 27-OCT-2016
MOVED TO FURTHER UP TO ALLOW THE L_OFFER TO BE PASSED TO THE DETAIL PAGE FROM THE STUDENT ID BUTTON
       if (l_embargo_active = 'N') 
                     then
                       
                       open   get_decision_details_c (p_current => 'Y'
                                                     ,p_earlier => 'N');
                       fetch  get_decision_details_c into l_decision_code   -- actual code
                                                         ,l_decision_date
                                                         ,l_UF_Decision     -- Y/N                       
                                                         ,l_C_Decision     -- actual code
                                                         ,l_offer;
                       close get_decision_details_c;
                       
                  elsif l_embargo_active = 'Y'  
                    then

-- mdx ADM July 2016 start
-- note the admt type can be changed to CR or DA for a UCAS applicant
                       if l_skrsain_source = 'U' then --and l_saradap_admt_code = '9' then
                         -- get earlier than embargo start date
-- mdx ADM July 2016 start
                          open   get_decision_details_c (p_current => 'N'
                                                        ,p_earlier => 'Y');
                          fetch  get_decision_details_c into l_decision_code   -- actual code
                                                            ,l_decision_date
                                                            ,l_UF_Decision     -- Y/N                       
                                                            ,l_C_Decision     -- actual code
                                                            ,l_offer;
                          close get_decision_details_c; 
                       else -- same as embargo not active
                     
                          open   get_decision_details_c (p_current => 'Y'
                                                        ,p_earlier => 'N');
                          fetch  get_decision_details_c into l_decision_code   -- actual code
                                                            ,l_decision_date
                                                            ,l_UF_Decision     -- Y/N                       
                                                            ,l_C_Decision     -- actual code
                                                            ,l_offer;
                          close get_decision_details_c; 
                      end if;                     
                  end if;
*/
                              
         /*      twbkfrmt.p_tabledataopen; 
               HTP.print( to_char(nvl(l_last_updated,l_decision_date),'fxDD-MON-YYYY')||'&nbsp;&nbsp;');
         */      
              -- htp.print('sabnstu_web_last_access    = '||l_sabnstu_web_last_access||'<br>sabnstu_last_login_date    = '||l_sabnstu_last_login_date||'<br>mdx_sabnstu_web_last_access = '||l_mdx_sabnstu_web_last_access||'<br>mdx_sabnstu_last_login_date = '||l_mdx_sabnstu_last_login_date);
                         
               twbkfrmt.p_tabledataclose; 
               
               -- Status
               twbkfrmt.p_tabledataopen; 
               
               if l_status <> '~' 
                 then
                      HTP.print(l_status||'&nbsp;&nbsp;'); -- Online apps that are incomplete or submitted but not pushed yet
               else
                              
                 l_status := mdx_get_status_f (l_pidm
                                              ,aidm
                                              ,l_application_type
                                              ,l_query
                                              ,l_status
                                              ,l_appno  -- sarhead_appl_no if not yet pushed, pushed & UCAS apps saradap_appl_no
                                              ,l_term_code_entry
                                              ,l_decision_code
                                              ,l_UF_Decision
                                              ,l_C_Decision
                                              ,l_saradap_admt_code
                                              ,l_skrsain_source
                                              ,l_offer); 
                            
                   -- ADM Nov 2016 Offer Letter changes - START            
                   --HTP.print (nvl(l_status,l_decision_code)||'&nbsp;&nbsp;');
                   if ( nvl(l_c_decision,'~') <> '~' and l_offer_letter_exists = 'Y' )
                      then
                      
                       HTP.formopen (twbkwbis.f_cgibin || 'bwskalog.P_ProcLoginNon', 'post','_blank');
                       htp.formHidden ('PAGE_ROUTE', 'OFFER_LETTER');
                       twbkfrmt.P_FormHidden ('in_id',l_webid);
                       twbkfrmt.P_FormHidden ('pin',l_web_pin); 
                       htp.formHidden ('NEWID', NULL);
                       htp.formHidden ('NEWPIN', NULL);
                       htp.formHidden ('VERIFYPIN', NULL);
                       htp.formHidden ('SUBMIT_BTN', NULL);
                       htp.formHidden ('p_appl_no', l_appno);
                       htp.formHidden ('p_term_code',l_term_code_entry);  
                    
                       -- ADM 07-NOV-2016 start
                        if nvl(l_webid,'~') <> '~' then
                        -- ADM 07-NOV-2016 end 
                    
                            htp.p('<input type="submit" value="'||nvl(l_status,l_decision_code)||'"/>'); 
                    
                        else
                    
                           HTP.print (nvl(l_status,l_decision_code)||'&nbsp;&nbsp;');
                        end if;                     
                   
                        htp.formclose; 
                      
                   else
                      HTP.print (nvl(l_status,l_decision_code)||'&nbsp;&nbsp;');
                   end if;
                   -- ADM Nov 2016 Offer Letter changes - END            

               end if;
/*               
-- 27-OCT-2016
MOVED TO THE CODE FOR THE STUDENT ID BUTTON

         if l_application_type||l_query <> 'OAI' then  -- only pass the parameter if not an incomplete online app
         
               twbkfrmt.P_FormHidden ('p_offer',l_offer); 
         --      HTP.print(nvl(l_C_Decision,l_decision_code));--(nvl(l_status,l_decision_code));
         end if;  
*/ 
 
               twbkfrmt.p_tabledataclose;                

               -- My Actions
               twbkfrmt.p_tabledataopen; 
               

               -- only display the professional_checks link if the applicant is a CF or UF applicant

              if l_professional_checks = 'Y'
                then
                   if l_UF_decision = 'Y'
                     then
                       l_display_prof_check_link := 'Y';
                   elsif l_c_decision = 'CF'
                     then
                       l_display_prof_check_link := 'Y';
                   end if;
              end if;
--             HTP.PRINT ('l_C_Decision = '||l_C_Decision);
 --            HTP.PRINT ('l_professional_checks AFTER = '||l_professional_checks);
                                  
               l_my_actions := mdx_get_my_actions_f (l_pidm
                                                    ,aidm
                                                    ,l_application_type
                                                    ,l_query
                                                    ,l_status
                                                    ,l_appno  -- sarhead_appl_no if not yet pushed, pushed & UCAS apps saradap_appl_no
                                                    ,l_term_code_entry
                                                    ,l_decision_code
                                                    ,l_saradap_admt_code
                                                    ,l_skrsain_source
                                                    ,l_professional_checks);  -- decided it was not necessary to actually create the link in the function
                            
              -- HTP.print(l_my_actions);   
                if l_my_actions = 'Resume' then
                
                     HTP.formopen (twbkwbis.f_cgibin || 'bwskalog.P_ProcLoginNon', 'post','_blank');
                     htp.formHidden ('PAGE_ROUTE', 'AGENT_RESUME');
                     twbkfrmt.P_FormHidden ('in_id',l_webid);
                     twbkfrmt.P_FormHidden ('pin',l_web_pin); 
                     htp.formHidden ('NEWID', NULL);
                     htp.formHidden ('NEWPIN', NULL);
                     htp.formHidden ('VERIFYPIN', NULL);
                     htp.formHidden ('SUBMIT_BTN', NULL);
                     htp.formHidden ('p_appl_no', l_appno);
                     htp.formHidden ('p_term_code',l_term_code_entry); 
                
                    htp.p('<input type="submit" value="'||l_my_actions ||'"/>'); 
                      
                    htp.formclose;  
                      
                elsif upper(l_my_actions) = 'SUBMIT FURTHER INFORMATION' then
                
                     HTP.formopen (twbkwbis.f_cgibin || 'bwskalog.P_ProcLoginNon', 'post','_blank');
                     htp.formHidden ('PAGE_ROUTE', 'AGENT_DOCUPLOAD');
                     twbkfrmt.P_FormHidden ('in_id',l_webid);
                     twbkfrmt.P_FormHidden ('pin',l_web_pin); 
                     htp.formHidden ('NEWID', NULL);
                     htp.formHidden ('NEWPIN', NULL);
                     htp.formHidden ('VERIFYPIN', NULL);
                     htp.formHidden ('SUBMIT_BTN', NULL);
                     htp.formHidden ('p_appl_no', l_appno);
                     htp.formHidden ('p_term_code',l_term_code_entry);  
                    
                    -- ADM 07-NOV-2016 start
                    if nvl(l_webid,'~') <> '~' then
                    -- ADM 07-NOV-2016 end 
                    
                        htp.p('<input type="submit" value="'||l_my_actions ||'"/>'); 
                        
                    -- ADM 07-NOV-2016 start    
                    else
                    
                       HTP.print(l_my_actions);
                    
                    end if;
                    -- ADM 07-NOV-2016 end
                      
                    htp.formclose;  

-- ADM Nov 2016 Offer Letter changes - START
                    
               elsif upper(l_my_actions) = 'VIEW OFFER' then
               
                   if l_offer_letter_exists = 'Y' then
                     
                     HTP.formopen (twbkwbis.f_cgibin || 'bwskalog.P_ProcLoginNon', 'post','_blank');
                     htp.formHidden ('PAGE_ROUTE', 'OFFER_LETTER');
                     twbkfrmt.P_FormHidden ('in_id',l_webid);
                     twbkfrmt.P_FormHidden ('pin',l_web_pin); 
                     htp.formHidden ('NEWID', NULL);
                     htp.formHidden ('NEWPIN', NULL);
                     htp.formHidden ('VERIFYPIN', NULL);
                     htp.formHidden ('SUBMIT_BTN', NULL);
                     htp.formHidden ('p_appl_no', l_appno);
                     htp.formHidden ('p_term_code',l_term_code_entry);  

                    if nvl(l_webid,'~') <> '~' then
                    
                        htp.p('<input type="submit" value="'||l_my_actions ||'"/>'); 
                        
                    else
                    
                       --HTP.print(l_my_actions);
                       HTP.print (bwskalog.mdx_display_info_f('mdx_agent_portal_pkg.mdx_agent_applicant_list_p','VIEW_OFFER_NO_LINK'));
                       
                    end if;
                      
                    htp.formclose; 
                    
                  else 
                     -- HTP.print(l_my_actions);
                     HTP.print (bwskalog.mdx_display_info_f('mdx_agent_portal_pkg.mdx_agent_applicant_list_p','VIEW_OFFER_NO_LINK'));
                  end if;
                      
-- ADM Nov 2016 Offer Letter changes - END    
                      
                else 
                      HTP.print(l_my_actions);
                      
                end if;
               
               
               if l_display_prof_check_link = 'Y' then -- only display the additional Professional checks link if UF or CF
                 
                    
               
                  -- htp.print ('<br><a href="bwskalog.mdx_applicant_prof_checks_p?appno='||l_appno||'&p_term_code_entry='||l_term_code_entry||'" style="color:red">Professional checks</a>');
               
                     HTP.formopen (twbkwbis.f_cgibin || 'bwskalog.P_ProcLoginNon', 'post','_blank');
                     htp.formHidden ('PAGE_ROUTE', 'PROF_CHECKS');
                     twbkfrmt.P_FormHidden ('in_id',l_webid);
                     twbkfrmt.P_FormHidden ('pin',l_web_pin); 
                     htp.formHidden ('NEWID', NULL);
                     htp.formHidden ('NEWPIN', NULL);
                     htp.formHidden ('VERIFYPIN', NULL);
                     htp.formHidden ('SUBMIT_BTN', NULL);
                     htp.formHidden ('p_appl_no', l_appno);
                     htp.formHidden ('p_term_code',l_term_code_entry);  
               
                     -- ADM 07-NOV-2016 start
                     if nvl(l_webid,'~') <> '~' then
                     -- ADM 07-NOV-2016 end
                     
                         htp.p('<input type="submit" value="Professional checks"/>'); 
                         
                     -- ADM 07-NOV-2016 start
                     else
                     
                        htp.p('Professional checks');
                        
                     end if;
                     -- ADM 07-NOV-2016 end
                     
                    htp.formclose;                
               
               end if;

               twbkfrmt.p_tabledataclose; 
 
                -- Applicant Agent Name - 
               twbkfrmt.p_tabledataopen; 
               HTP.print(l_applicant_agent_name||'&nbsp;&nbsp;');
               twbkfrmt.p_tabledataclose; 
       
          twbkfrmt.p_tablerowclose;

-- ADM AUG 2017 START
-- added to hide any UCAS application from the list of students if the embargo period is active
end if;
-- ADM AUG 2017 END
          
     --     HTP.formclose;         
          
          l_pidm                   := null;
          l_appno                  := null;         
          L_term_code_entry        := null;
          l_sarhead_appl_comp_ind  := null;
          l_sarhead_process_ind    := null;
          l_sarhead_wapp_code      := null;
          l_application_type       := null;
          l_query                  := null;
          l_program                := null;
          l_prog_desc              := null;
          l_term_desc              := null;
          l_status                 := null;
          l_app_created            := null;
          l_skrsain_source         := null;
          l_saradap_admt_code      := null;
          l_last_updated           := null;
          l_decision_code          := null;-- actual code
          l_UF_Decision            := null;-- Y/N                       
          l_C_Decision             := null;-- actual code
          l_offer_text             := null;
          l_offer                  := null;
          l_my_actions             := null;
          l_professional_checks    := null;
          l_display_prof_check_link :='N';
          l_student_id             := null;
          l_last_name              := null;
          l_first_name             := null;
          l_middle_name            := null;
          l_birth_date             := null;
          l_resd_desc              := null;
          l_aidm                   := null;
          l_skrsain_applicant_no   := null;
          l_webid                  := null;
          l_web_pin                := null;
          l_applicant_agent_name   := null;
  
          end loop;
          
          close get_details_c;
          
 -- the create new application code was copied from the Ellucian code
 -- this will need to be pointed at the new search page once Jeff has done this 
 -- new page

/* NOT REQUIRED FOR AGENT PORTAL
twbkfrmt.p_tablerowopen;
      twbkfrmt.p_tabledata (
         twbkfrmt.f_printanchor (
            twbkfrmt.f_encodeurl (
               twbkwbis.f_cgibin || 'mdx_course_search_pkg.mdx_disp_search_page_p'
            ),
            g$_nls.get ('BWSKALO1-0054', 'SQL', 'New')
         )
      );
      twbkfrmt.p_tabledata (
         g$_nls.get ('BWSKALO1-0055', 'SQL', 'Create a new application'),
         ccolspan   => '4'
      );
      twbkfrmt.p_tablerowclose; */
      twbkfrmt.p_tableclose;
 
          
          twbkfrmt.p_tableclose;   
  --        HTP.br;   
 end if;   
 
 end if; -- check if an active agent
 htp.p('<br></br>');
 
-- htp.p('<form> <input TYPE="button" onclick="goBack()" value="Home"> </form>');
-- htp.p('<input TYPE="button" onclick="goBack()" value="Home">');
 
 --htp.p('<a href="#" onclick="history.go(-1)">Return to Homepage</a>');

 htp.p('<form> <input TYPE="button" onclick="history.go(-1)" value="Return to Homepage"> </form>');
 
/* htp.p('<FORM>
 <INPUT TYPE="button" onClick="parent.location=''mdxdata.mdx_agent_pkg.mdx_landing_p''">
 </FORM>'); */
 
 
--  htp.p('<form> <input TYPE="submit" href="#" onclick="history.go(-1)" value="Home"> </form>');
  
-- htp.p('<form> <input type=submit onclick="history.go(-1)" value="HomeXX"> </form>'); 

  --mdxdata.mdx_agent_pkg.mdx_landing_p
 
 twbkwbis.p_closedoc;
 
-- mdx adm end Oct 2015

-- mdx adm start Oct 2015
/*
      OPEN getchoicesc (aidm);
      FETCH getchoicesc INTO app_rec;

      IF getchoicesc%NOTFOUND
      THEN
         OPEN saklibs.sarhead_not_reviewed_c (aidm, bwskalog.pidm);
         FETCH saklibs.sarhead_not_reviewed_c INTO sarhead_rec;

         IF saklibs.sarhead_not_reviewed_c%NOTFOUND
         THEN
            OPEN saklibs.saradap_by_pidm_c (aidm, bwskalog.pidm);
            FETCH saklibs.saradap_by_pidm_c INTO saradap_rec;

            IF saklibs.saradap_by_pidm_c%NOTFOUND
            THEN
               CLOSE getchoicesc;
               CLOSE saklibs.sarhead_not_reviewed_c;
               CLOSE saklibs.saradap_by_pidm_c;
               p_selnewapp (NULL, 'Y', in_secured);
               RETURN;
            END IF;

            CLOSE saklibs.saradap_by_pidm_c;
         END IF;

         CLOSE saklibs.sarhead_not_reviewed_c;
      END IF;

      --
      twbkwbis.p_opendoc ('bwskalog.P_DispChoices', exit_url => app_exit_url);
      twbkwbis.p_dispinfo ('bwskalog.P_DispChoices');
      p_printmsg;
      --
      twbkfrmt.p_tableopen (
         'DATADISPLAY',
         cattributes   => 'SUMMARY= "' ||
                             g$_nls.get ('BWSKALO1-0032',
                                'SQL',
                                'This table displays the applications in progress.') ||
                             '"WIDTH="100%"',
         ccaption      => g$_nls.get ('BWSKALO1-0033',
                             'SQL',
                             'Applications in Progress')
      );
      twbkfrmt.p_tablerowopen;
      twbkfrmt.p_tabledataheader (
         g$_nls.get ('BWSKALO1-0034', 'SQL', 'Admission Term'),
         cattributes   => 'abbr="' || g$_nls.get ('BWSKALO1-0035',
                                         'SQL',
                                         'Term') ||
                             '"'
      );
      twbkfrmt.p_tabledataheader (
         g$_nls.get ('BWSKALO1-0036', 'SQL', 'Application Type'),
         cattributes   => 'abbr="' || g$_nls.get ('BWSKALO1-0037',
                                         'SQL',
                                         'Type') ||
                             '"'
      );

      IF f_preference_defined(NULL)
      THEN
         preference_usage := TRUE;
         twbkfrmt.p_tabledataheader (
            g$_nls.get ('BWSKALO1-0038', 'SQL', 'Application Preference'),
            cattributes   => 'abbr="' || g$_nls.get ('BWSKALO1-0039',
                                            'SQL',
                                            'Pref') ||
                                '"'||
                             'WIDTH="10%"'
         );
      END IF;

      twbkfrmt.p_tabledataheader (
         g$_nls.get ('BWSKALO1-0040', 'SQL', 'Field of Study'),
         cattributes   => 'abbr="' ||
                             g$_nls.get ('BWSKALO1-0041', 'SQL', 'Major') ||
                             '"'
      );
      twbkfrmt.p_tabledataheader (
         g$_nls.get ('BWSKALO1-0042', 'SQL', 'Date Created'),
         cattributes   => 'abbr="' ||
                             g$_nls.get ('BWSKALO1-0043', 'SQL', 'Created') ||
                             '"'
      );
      twbkfrmt.p_tabledataheader (
         g$_nls.get ('BWSKALO1-0044', 'SQL', 'Last Section Updated'),
         cattributes   => 'abbr="' || g$_nls.get ('BWSKALO1-0045',
                                         'SQL',
                                         'Last') ||
                             '"'
      );
      twbkfrmt.p_tablerowclose;

      --
      WHILE getchoicesc%FOUND
      LOOP
         twbkfrmt.p_tablerowopen;

         IF app_rec.comp_ind = 'Y'
         THEN
            twbkfrmt.p_tabledata (app_rec.term_desc);
         ELSE
            twbkfrmt.p_tabledata (
               twbkfrmt.f_printanchor (
                  twbkfrmt.f_encodeurl (
                     'bwskalog.P_DispIndex' || '?appno=' ||
                     TO_CHAR (app_rec.appno)),
                  app_rec.term_desc,
                  cattributes => 'onMouseOver="window.status=''' ||
                             g$_nls.get ('BWSKALO1-0046',
                                'SQL',
                                'Update Application information') ||
                             '''; ' ||
                             ' return true" ' ||
                             'onFocus="window.status=''' ||
                             g$_nls.get ('BWSKALO1-0047',
                                'SQL',
                                'Update Application information') ||
                             '''; ' ||
                             ' return true" ' ||
                             'onMouseOut="window.status=''''; ' ||
                             ' return true"' ||
                             'onBlur="window.status=''''; ' ||
                             ' return true"'
               ), cattributes => 'BYPASS_ESC=Y'
            );
         END IF;

         twbkfrmt.p_tabledata (app_rec.wapp_desc);
         IF preference_usage
         THEN
            IF f_preference_defined(app_rec.wapp_code)
            THEN
               twbkfrmt.p_tabledata (
                  twbkfrmt.f_printanchor (
                        twbkfrmt.f_encodeurl (
                           'bwskaprf.p_disp_pref' ||
                              '?appno=' || TO_CHAR (app_rec.appno) ||
                              '&wsct=PREFERENCE' ||
                              '&p_origin=APPLMENU'||
                              '&p_sec_men=' || sec_men),
                        nvl(to_char(app_rec.appl_pref),
                            g$_nls.get ('BWSKALO1-0048','SQL','Not entered')),
                        cattributes => 'onMouseOver="window.status=''' ||
                                         g$_nls.get ('BWSKALO1-0049',
                                            'SQL',
                                            'Update Application Preference') ||
                                         '''; ' ||
                                         ' return true" ' ||
                                         'onFocus="window.status=''' ||
                                         g$_nls.get ('BWSKALO1-0050',
                                            'SQL',
                                            'Update Application Preference') ||
                                         '''; ' ||
                                         ' return true" ' ||
                                         'onMouseOut="window.status=''''; ' ||
                                         ' return true"' ||
                                         'onBlur="window.status=''''; ' ||
                                         ' return true"'
                  ), cattributes => 'BYPASS_ESC=Y'
               );
            ELSE
               twbkfrmt.p_tabledata (
                  nvl(to_char(app_rec.appl_pref),
                      g$_nls.get ('BWSKALO1-0051','SQL','Not entered')));
            END IF;
         END IF;
         --

         p_extractcurr (
            f_top_priority_sarefos (aidm, app_rec.appno),
            program_desc,
            curr_rule
         );
         twbkfrmt.p_tabledata (program_desc);
         --

         twbkfrmt.p_tabledata (
            TO_CHAR (app_rec.add_date, twbklibs.date_display_fmt)
         );

         IF app_rec.bookmark IS NOT NULL
         THEN
            OPEN getappsectionsheadc (app_rec.bookmark, aidm, app_rec.appno);
            FETCH getappsectionsheadc INTO wapp_wsct_desc;

            IF getappsectionsheadc%NOTFOUND
            THEN
               twbkfrmt.p_tabledatadead;
            ELSE
               OPEN stkwsct.stvwsctc (app_rec.bookmark);
               FETCH stkwsct.stvwsctc INTO stvwsct_rec;

               IF stkwsct.stvwsctc%NOTFOUND
               THEN
                  twbkfrmt.p_tabledatadead;
               ELSE
                  twbkfrmt.p_tabledata (
                     twbkfrmt.f_printanchor (
                        twbkfrmt.f_encodeurl (
                           stvwsct_rec.stvwsct_procedure || '?appno=' ||
                              TO_CHAR (app_rec.appno) ||
                              '&wsct=' || app_rec.bookmark
                        ),
                        wapp_wsct_desc,
                        cattributes => 'onMouseOver="window.status=''' ||
                             g$_nls.get ('BWSKALO1-0052',
                                'SQL',
                                'Update %01% information', wapp_wsct_desc
                             ) ||
                             '''; ' ||
                             ' return true" ' ||
                             'onFocus="window.status=''' ||
                             g$_nls.get ('BWSKALO1-0053',
                                'SQL',
                                'Update %01% information', wapp_wsct_desc
                             ) ||
                             '''; ' ||
                             ' return true" ' ||
                             'onMouseOut="window.status=''''; ' ||
                             ' return true"' ||
                             'onBlur="window.status=''''; ' ||
                             ' return true"'
                     ), cattributes => 'BYPASS_ESC=Y'
                  );
               END IF;

               CLOSE stkwsct.stvwsctc;
            END IF;

            CLOSE getappsectionsheadc;
         ELSE
            twbkfrmt.p_tabledatadead;
         END IF;

         twbkfrmt.p_tablerowclose;
         --
         FETCH getchoicesc INTO app_rec;

         IF getchoicesc%NOTFOUND
         THEN
            EXIT;
         END IF;
      END LOOP;

      CLOSE getchoicesc;
      --
      twbkfrmt.p_tablerowopen;
      twbkfrmt.p_tabledata (
         twbkfrmt.f_printanchor (
            twbkfrmt.f_encodeurl (
               twbkwbis.f_cgibin || 'bwskalog.P_SelNewApp' ||
                  '?wapp=&noapps=&in_secured=' ||
                  in_secured
            ),
            g$_nls.get ('BWSKALO1-0054', 'SQL', 'New')
         )
      );
      twbkfrmt.p_tabledata (
         g$_nls.get ('BWSKALO1-0055', 'SQL', 'Create a new application'),
         ccolspan   => '4'
      );
      twbkfrmt.p_tablerowclose;
      twbkfrmt.p_tableclose;
      --
      HTP.br;

      --
      IF pidm IS NULL
      THEN
         OPEN getsabidenaidmc (aidm);
         FETCH getsabidenaidmc INTO sabiden_rec;

         IF getsabidenaidmc%FOUND
         THEN
            pidm := sabiden_rec.sabiden_pidm;
         END IF;

         CLOSE getsabidenaidmc;
      END IF;

      bwskasta.p_dispapplications(in_secured);

*/
-- mdx adm end Oct 2015


     -- need all 3 of the following calls to back_url for it to use the return to Landing page in this package

/*      IF back_url IS NULL
      THEN
         back_url := app_exit_url;
         dflt_back_link :=
                       g$_nls.get ('BWSKALO1-0056', 'SQL', 'Return to Homepage');
      END IF; 
*/

      /* back_url still null means this session is secured side - */
      /* and we are returning from completed application submission */

/*      IF back_url IS NULL
      THEN
         back_url :=
            twbkwbis.f_cgibin || 'twbkwbis.P_GenMenu' || '?name=bmenu.P_StuMainMnu';
         dflt_back_link := g$_nls.get ('BWSKALO1-0057', 'SQL', 'Return to Menu');
      END IF;

    IF back_url IS not null then
      twbkwbis.p_closedoc (
       --  curr_release,
       '8.5.4',
         back_url         => back_url,
         dflt_back_link   => dflt_back_link
      ); 
   end if; */

/*      twbkwbis.p_closedoc (
       --  curr_release,
       '8.5.4',
         back_url         => back_url,
         dflt_back_link   => dflt_back_link
      ); */
      
-- mdx adm start Oct 2015
/*
      OPEN saklibs.sarerulc ('EMAILSENDADDR');
      FETCH saklibs.sarerulc INTO sarerul_rec;

      IF     saklibs.sarerulc%FOUND
         AND sarerul_rec.sarerul_value IS NOT NULL
      THEN
         OPEN getidc (aidm);
         FETCH getidc INTO in_id;
         CLOSE getidc;
         CLOSE saklibs.sarerulc;
         p_getnames (aidm);
         email_addr :=
           sarerul_rec.sarerul_value || '?subject=' || in_id || ' - ' ||
              first_name ||
              ' ' ||
              last_name;
         OPEN saklibs.sarerulc ('EMAILSENDLINK');
         FETCH saklibs.sarerulc INTO sarerul_rec;

         IF     saklibs.sarerulc%FOUND
            AND sarerul_rec.sarerul_value IS NOT NULL
         THEN
            email_link := sarerul_rec.sarerul_value;
         ELSE
            email_link :=
                g$_nls.get ('BWSKALO1-0058', 'SQL', 'Send e-mail to Admissions');
         END IF;

         CLOSE saklibs.sarerulc;
         HTP.br;
         HTP.mailto (email_addr, email_link);
      ELSE
         CLOSE saklibs.sarerulc;
      END IF;
*/
 --twbkwbis.p_closedoc;

   END  mdx_agent_applicant_list_p;
-------------------------------------------------------------------------------
   PROCEDURE mdx_agent_applicant_detail_p (p_xceduz              varchar2 -- note this is just a security param to make hacking page harder
                                          ,p_pidm                number   default null
                                          ,p_aidm                number   default null
                                          ,p_appno               number   default null
                                          ,p_term_code_entry     varchar2  default null
                                          ,p_skrsain_source      varchar2 default null
                                          ,p_skrsain_applicant_no varchar2 default null
                                          ,p_app_type            varchar2 default null
                                          ,p_offer               number default null
                                          ,in_id                 varchar2 default null
                                          ,pin                   varchar2 default null
                                          ,msg                   varchar2 default null   
                                          ,p_agent_id            varchar2  default null
                                          ,p_comment             varchar2 default null)
   is
   
   -- NOTE THIS PAGE IS ONLY AVAILABLE FOR APPLICATIONS FULLY LOADED INTO MISIS PRIMARY ADMISSIONS TABLES
   -- INCOMPLETE APPLICATIONS SHOULD BE DIRECTED BACK TO RESUME????


      l_embargo_active          char(1) default 'N';    
      l_embargo_start_date      date;
      l_embargo_start_time      gtvsdax.GTVSDAX_TRANSLATION_CODE%type;      
      l_embargo_org_start_date  date;
      l_embargo_end_date        date;
      l_embargo_org_end_date    date;
      l_embargo_end_time        gtvsdax.GTVSDAX_TRANSLATION_CODE%type;  
   --
  l_curr_release   CONSTANT VARCHAR2 (10)             := '8.5.4';
  cell_msg_flag    VARCHAR2 (1);
  display_msg      varchar2(20000);   -- made it this big for testing the large fields
  l_display_info_exists  char(1) default 'N';
   --
   l_aidm            sabnstu.sabnstu_aidm%type;
   l_student_id      varchar2(200);
   l_prefix          spbpers.spbpers_name_prefix%type;
   l_last_name       spriden.spriden_last_name%type;
   l_first_name      spriden.spriden_first_name%type;
   l_middle_name     spriden.spriden_mi%type;
   l_skype_id        varchar2(200);
   l_email           varchar2(200);
   l_telephone       varchar2(200);   
   l_regional_office skrsain.skrsain_ssdt_code_inst2%type;
   l_prog_desc       mdx_prog.mdx_prog_long_title%type;
   l_campus_desc     stvcamp.stvcamp_desc%type;
   l_term_code_entry_desc stvterm.stvterm_desc%type;
   l_mode            SARAATT.SARAATT_ATTS_CODE%type; 
   l_year            SARAATT.SARAATT_ATTS_CODE%type; 
   l_agency_code     skrsain.skrsain_ssdt_code_inst3%type;
   l_birth_date      spbpers.spbpers_birth_date%type;
   l_ethnic_code     spbpers.spbpers_ethn_code%type;
   l_ethnic_desc     stvethn.stvethn_desc%type;
   l_gender          varchar2(20);--spbpers.spbpers_sex%type;
   l_resd_code              saradap.saradap_resd_code%type;
   l_country_perm_resd      skvssdt.skvssdt_short_title%type;
   l_birth_country          skvssdt.skvssdt_short_title%type;
   l_nationality            skvssdt.skvssdt_short_title%type;
   l_visa_req               skbspin.skbspin_studentvisarequired%type;
   l_passport_no            skbspin.skbspin_passportno%type;
   l_passport_issued        skbspin.skbspin_passportplaceissued%type;
   l_passport_expiry        skbspin.skbspin_passportexpirydate%type;  
   l_level_code      saradap.saradap_levl_code%type;
   l_display_fee_section char(1) default 'N';
   l_ro_email          goremal.GOREMAL_EMAIL_ADDRESS%type;
   l_pre_sessional_required   char(1) default 'N';
   -- ADM Nov 2016 Offer Letter changes - START
   l_offer_letter_exists   char(1) default 'N';
   -- ADM Nov 2016 Offer Letter changes - END     
   --
   l_SPRMEDI_MEDI_CODE  sprmedi.SPRMEDI_MEDI_CODE%type;
   l_stvmedi_desc       stvmedi.stvmedi_desc%type;
   l_disability_list    varchar2(1000);
   --
   l_address1        spraddr.spraddr_street_line1%type;
   l_address2        spraddr.spraddr_street_line2%type;
   l_address3        spraddr.spraddr_street_line3%type;
   l_city            spraddr.spraddr_city%type;
   l_postcode        spraddr.spraddr_zip%type;
   l_address_country stvnatn.stvnatn_nation%type;
   l_address_string  varchar2(2000);
   --
   l_accom_contract_type    stvartp.stvartp_desc%type;
   l_accom_application_date SLBRMAP.SLBRMAP_ADD_DATE%type;
   l_accom_offer_status     stvascd.stvascd_desc%type;
   l_accom_offer_date       slrrasg.slrrasg_ascd_date%type;
   l_accom_hall             stvbldg.stvbldg_desc %type;
   --
   l_status_code     sarappd.sarappd_apdc_code%type;
   l_status_date     sarappd.sarappd_apdc_date%type;
   l_status_desc     stvapdc.stvapdc_desc%type; 
   l_status_seqno    SARAPPD.SARAPPD_SEQ_NO%type;
   l_get_offer       char(1) default 'N';
   l_skrudec_off_lib_string        skrudec.skrudec_off_lib_string%type;
   l_skrudec_exp_text              skrudec.skrudec_exp_text%type;
   --
   l_sarchkl_admr_code  sarchkl.sarchkl_admr_code%type;
   l_stvadmr_desc       stvadmr.stvadmr_desc%type;
   l_SARCHKL_CKST_CODE  sarchkl.SARCHKL_CKST_CODE%type;
   l_sarchkl_receive_date  sarchkl.sarchkl_receive_date%type;
   l_SARCHKL_COMMENT     varchar2(2000);
   --
--   l_tuition_fee      mdx_rego_payment.mdx_rego_tuition_fee%type;
--   l_deposit          mdx_rego_payment.mdx_rego_deposit%type;
--
-- FINANCE taken from bwskopay
  gtv_ext_code          gtvsdax.gtvsdax_external_code%type := 'N';
  pay_amt               number;
  m_pay                 number;
  l_pay                 number;
  l_amt                 number;
  pay_count             number := 0;
  row_count             number := 0;
  tot_amt               number := 0;
  std_id                spriden.spriden_id%type;
  web_pay_exists        number := 0;
  l_row_count           number := 0;
  l_fee_exists          varchar2(1) := 'N';
  l_total_tui           tbraccd.tbraccd_balance%type := 0;
  l_ttvdcat_desc        ttvdcat.ttvdcat_desc%type := null;
  l_deposit             mdx_rego_payment.mdx_rego_deposit%type := 0;
  l_total_csh           tbraccd.tbraccd_balance%type := 0;
  l_total_outstanding   tbraccd.tbraccd_balance%type := 0;
-- jmp start june 2016
  l_term_desc 		stvterm.stvterm_desc%type;
  l_mapped_DEP_PAY_DIS	SKVSSDT.SKVSSDT_TITLE%type;
  l_dcat_maping_code	SKVSSDT.SKVSSDT_TITLE%type;
   -- 
  l_comment_rec      saracmt%rowtype;
  l_comment           varchar2(5000);
  ccolspan            varchar2(30) default null;
--  
   l_webid    mdx_sabnstu.mdx_sabnstu_id%type;
   l_web_pin  mdx_sabnstu.mdx_sabnstu_pin%type;
   l_login_url  varchar2(500);
   --
   cursor get_login_details_c is
   SELECT mdx_sabnstu_id
         ,mdx_sabnstu_pin
   FROM mdx_sabnstu
   WHERE mdx_sabnstu_pidm = p_pidm
   union
   select sabnstu_id
         ,sabnstu_pin
   from sabnstu
   where sabnstu_aidm = p_aidm;
--
cursor get_ucas_embargo_dates_c is
select (select GTVSDAX_REPORTING_DATE     
            --  ,gtvsdax_translation_code   embargo_end_date
        from gtvsdax
        where  gtvsdax_external_code       = 'START'
        and    gtvsdax_internal_code       = 'UCASEMBARG'
        and    gtvsdax_internal_code_group = 'MDX_APPL_SS') embargo_start_date
      ,(select gtvsdax_translation_code     
        from gtvsdax
        where  gtvsdax_external_code       = 'START'
        and    gtvsdax_internal_code       = 'UCASEMBARG'
        and    gtvsdax_internal_code_group = 'MDX_APPL_SS') embargo_start_time       
       ,(select GTVSDAX_REPORTING_DATE     
            --  ,gtvsdax_translation_code   embargo_end_date
        from gtvsdax
        where  gtvsdax_external_code       = 'END'
        and    gtvsdax_internal_code       = 'UCASEMBARG'
        and    gtvsdax_internal_code_group = 'MDX_APPL_SS') embargo_end_date
      ,(select gtvsdax_translation_code     
        from gtvsdax
        where  gtvsdax_external_code       = 'END'
        and    gtvsdax_internal_code       = 'UCASEMBARG'
        and    gtvsdax_internal_code_group = 'MDX_APPL_SS') embargo_end_time 
from dual;

cursor get_aidm_c is
select mdx_sabnstu_aidm
from mdx_sabnstu
where mdx_sabnstu_id   = trim(l_email)
and   mdx_sabnstu_pidm = p_pidm;
   
/*   select sabnstu_id       -- student_id
         ,sarpers_prefix
         ,sarpers_last_name
         ,sarpers_first_name
         ,sarpers_middle_name1
         ,sabnstu_id       -- email
         ,(select SARRQST_ANSR_DESC
           from  sarrqst
           where sarrqst_wudq_no    = 44
           and   sarrqst_aidm       = p_aidm
           and   sarrqst_appl_seqno = p_appno) Skype_ID
         ,trim(substr(c.sarphon_phone,6))
  from  sarphon  c
        ,sarpers
        ,sabnstu
  where 1 = 1
  and  c.sarphon_seqno      = (select max(d.sarphon_seqno)
                              from sarphon d
                              where d.sarphon_pqlf_cde    = 'PR'
                              and   d.sarphon_appl_seqno  = c.sarphon_appl_seqno
                              and   d.sarphon_aidm        = c.sarphon_aidm)
  and  c.sarphon_pqlf_cde    = 'PR'
  and  c.sarphon_appl_seqno  = sarpers_appl_seqno
  and  c.sarphon_aidm        = sarpers_aidm
  and sarpers_appl_seqno = p_appno
  and sarpers_aidm       = p_aidm
  and sabnstu_aidm       = p_aidm
  and  nvl(p_pidm,'1')   = '1'
  union */
  cursor get_details_c (pl_pidm number
                       ,pl_aidm number
                       ,pl_appno number
                       ,pl_applicant_no varchar2
                       ,pl_term_code_entry varchar2)
  is
  select spriden_id   
        ,nvl(spbpers_name_prefix,decode(spbpers_sex,'F','Miss'
                                                   ,'M','Mr')) 
        ,spriden_last_name   
        ,spriden_first_name
        ,spriden_mi
        ,(SELECT GOREMAL_EMAIL_ADDRESS
          from goremal
          where 1 = 1
          and   goremal_status_ind = 'A'
          and   goremal_emal_code  = 'PV'
          and   goremal_pidm       = spriden_pidm
          and   rownum = 1)  Email       
        ,(SELECT GOREMAL_EMAIL_ADDRESS
          from goremal
          where 1 = 1
          and   goremal_status_ind = 'A'
          and   goremal_emal_code  = 'SK'
          and   goremal_pidm       = spriden_pidm
          and   rownum = 1)  Skype_ID
        ,(select a.sprtele_intl_access
          from sprtele  a
          where 1 = 1
          and a.sprtele_seqno              = (select max(b.sprtele_seqno)
                                             from sprtele b
                                             where nvl(b.SPRTELE_STATUS_IND,'A') = 'A'
                                             and b.SPRTELE_TELE_CODE            = 'PR'
                                             and b.sprtele_Pidm                 = a.sprtele_pidm)
          and nvl(a.SPRTELE_STATUS_IND,'A') = 'A'
          and a.SPRTELE_TELE_CODE           = 'PR'
          and a.sprtele_pidm                = spriden_pidm) telephone_no
        ,skrsain_ssdt_code_inst2        Regional_office
        ,mdx_prog_long_title
        ,(select stvcamp_desc
          from stvcamp
          where stvcamp_code = saradap_camp_code) Campus_desc
        ,(select stvterm_desc
          from stvterm
          where stvterm_code = saradap_term_code_entry) term_code_entry_desc
        ,(select SARAATT_ATTS_CODE
          from   saraatt
          where 1 = 1
          and substr(SARAATT_ATTS_CODE,1,1) = 'M'
          and SARAATT_appl_no               = saradap_appl_no
          and saraatt_term_code             = saradap_term_code_entry
          and saraatt_pidm                  = saradap_pidm
          and rownum = 1)  Mode_of_study
        ,(select SARAATT_ATTS_CODE
          from   saraatt
          where 1 = 1
          and substr(SARAATT_ATTS_CODE,1,2) = 'YR'
          and SARAATT_appl_no               = saradap_appl_no
          and saraatt_term_code             = saradap_term_code_entry
          and saraatt_pidm                  = saradap_pidm
          and rownum = 1)  Year_of_study    
         ,skrsain_ssdt_code_inst3      agency_code
         ,spbpers_birth_date
         ,spbpers_ethn_code
         ,nvl((select stvethn_desc
               from stvethn
              where stvethn_code = SPBPERS_ETHN_CODE),'Not supplied') enthic_desc
         ,nvl(decode(spbpers_sex,'F','Female'
                                ,'M','Male'
                                ,'N','Not Known'),'Not Known') gender
         ,saradap_resd_code
         ,(select decode(a.skvssdt_sdat_code_opt_1 ,'000', 'United Kingdom',skvssdt_short_title )
           from skvssdt a
           where SKVSSDT_SDAT_CODE_OPT_1   = skrsain_natn_code_domicile
           and  a.skvssdt_sdat_code_entity = 'HESA' 
           and  a.skvssdt_sdat_code_attr   = 'MDX_DOMICILE'
           and  a.skvssdt_status_ind       = 'A'  
           and  a.skvssdt_eff_date         <= sysdate
           and (a.skvssdt_term_date is null  or a.skvssdt_term_date   >= sysdate)) country_perm_resd
         ,(select decode(a.skvssdt_sdat_code_opt_1 ,'000', 'United Kingdom',skvssdt_short_title )
           from skvssdt a
           where SKVSSDT_SDAT_CODE_OPT_1   = skbspin_natn_code_birth 
           and  a.skvssdt_sdat_code_entity = 'HESA' 
           and  a.skvssdt_sdat_code_attr   = 'MDX_DOMICILE'
           and  a.skvssdt_status_ind       = 'A'  
           and  a.skvssdt_eff_date         <= sysdate
           and (a.skvssdt_term_date is null  or a.skvssdt_term_date   >= sysdate)) birth_country                            
         ,(select decode(a.skvssdt_sdat_code_opt_1 ,'000', 'United Kingdom',skvssdt_short_title )
           from skvssdt a
           where SKVSSDT_SDAT_CODE_OPT_1   = skbspin_natn_code_legal 
           and  a.skvssdt_sdat_code_entity = 'HESA' 
           and  a.skvssdt_sdat_code_attr   = 'MDX_DOMICILE'
           and  a.skvssdt_status_ind       = 'A'  
           and  a.skvssdt_eff_date         <= sysdate
           and (a.skvssdt_term_date is null  or a.skvssdt_term_date   >= sysdate)) nationality
          ,skbspin_studentvisarequired
          ,skbspin_passportno
          ,skbspin_passportplaceissued
          ,skbspin_passportexpirydate
          ,saradap_levl_code
          -- ADM 07-NOV-2016 start
          ,nvl((select distinct 'Y'
          -- ADM 07-NOV-2016 end
                from  sarappd
                where 1 = 1
                -- ADM Nov 2016 Offer Letter changes - START
                --and   sarappd_apdc_code       in ('U','UF','DU')
                and   sarappd_apdc_code       in ('U','UF','DU','UA','C','CF')
                -- ADM Nov 2016 Offer Letter changes - END                             
                and   sarappd_appl_no         = p_appno
                and   sarappd_term_code_entry = p_term_code_entry
                and   sarappd_pidm            = p_pidm),'N') display_fee_section
           ,(select nvl(goremal_comment,goremal_email_address)
             from  goremal
                  ,goradid
             where 1 = 1
             and nvl(goremal_status_ind,'A') = 'A'
             and GOREMAL_EMAL_CODE           = 'RO'
             and goremal_pidm                = goradid_pidm
             and GORADID_ADID_CODE           = 'REGO'
             and GORADID_ADDITIONAL_ID       = skrsain_ssdt_code_inst2
             and rownum = 1) regional_office_email
           ,nvl((select 'Y'
                 from  sarchkl
                 where sarchkl_admr_code = 'PRES'
                 and   sarchkl_term_code_entry = saradap_term_code_entry
                 and   sarchkl_appl_no         = saradap_appl_no
                 and   sarchkl_pidm            = saradap_pidm),'N') pre_sessional_applied
 -- ADM Nov 2016 Offer Letter changes - START  
            ,nvl((select distinct 'Y'
                  from MDX_OFFER_LETTER_LOG
                              where 1 = 1 --mdx_ofll_status     in ('PDF_GENERATED','EMAIL_SENT')
                              --and   nvl(MDX_OFLL_PDF_FILENAME,'~') <> '~'
                              and   mdx_ofll_status     in ('INITIAL'
                                                            ,'DATA_CHECK_FAILED'
                                                            ,'REQUESTED'
                                                            ,'REQUESTED_EVENING'
                                                            ,'HTML_EMAIL_GENERATED'
                                                            ,'HTML_GENERATED'
                                                            ,'HTML_FAILED'
                                                            ,'PDF_GENERATED'
                                                            ,'PDF_FAILED'
                                                            ,'EMAIL_NOT_REQUESTED'
                                                            ,'EMAIL_SENT'
                                                            ,'EMAIL_FAILED'
                                                            ,'EXCLUDED')
                              and   mdx_ofll_request_type <> 'DC'                              
                              and   MDX_OFLL_APPL_NO    = saradap_appl_no
                              and   MDX_OFLL_TERM_CODE  = saradap_term_code_entry
                              and   mdx_ofll_pidm       = saradap_pidm),'N') offer_letter_exists
 -- ADM Nov 2016 Offer Letter changes - END  
  from  skbspin
        ,skrsain
        ,spriden
        ,spbpers
        ,mdx_prog p1
        ,saradap
  where 1 = 1
  and  skbspin_pidm         = saradap_pidm
  and  spriden_change_ind   is null
  and  spriden_pidm         = saradap_pidm
  and  skrsain_applicant_no = pl_applicant_no
  and  skrsain_pidm         = saradap_pidm
  and  spbpers_pidm         = saradap_pidm
  and  mdx_prog_eff_term    = (select max(p2.mdx_prog_eff_term)
                               from mdx_prog p2
                               where 1 = 1
                               and   p2.mdx_prog_eff_term <= pl_term_code_entry
                               and   p2.mdx_prog_program   = p1.mdx_prog_program)
  and  p1.MDX_PROG_PROGRAM  = SARADAP_PROGRAM_1
  and  saradap_appl_no      = pl_appno 
  and  saradap_pidm         = pl_pidm
  and  nvl(pl_pidm,'1')      <> '1';
  
  cursor get_disability_c is
  select  SPRMEDI_MEDI_CODE
         ,stvmedi_desc
  from  stvmedi
       ,sprmedi 
  where stvmedi_code = SPRMEDI_MEDI_CODE
  and   sprmedi_pidm = p_pidm;
  
  cursor get_address_c is
  select spraddr_street_line1
        ,spraddr_street_line2
        ,spraddr_street_line3
        ,spraddr_city
        ,spraddr_zip
/* -- ADM 09-NOV-2016 
   -- we don't actually use the country field to hold the country for overseas 
   -- addresses.  MISIS FAQ indicates we use the city to hold the country for overseas        
        ,(select stvnatn_nation
          from stvnatn
          where stvnatn_code = decode(nvl(spraddr_natn_code,'.'),'.','000',spraddr_natn_code)) address_country */
  from spraddr
  where 1 = 1
  and sysdate                     between spraddr_from_date and nvl(spraddr_to_date,sysdate+1)
  and nvl(spraddr_status_ind,'A') = 'A'
  and spraddr_atyp_code           = 'PR'
  and spraddr_pidm                = p_pidm;
  
  cursor get_accom_c is
  select stvartp_desc         contract_type
        --,slbrmap_artp_code
        ,SLBRMAP_ADD_DATE     application_date
     --   ,a.slrrasg_ascd_code
        ,stvascd_desc         offer_status
        ,a.slrrasg_ascd_date  offer_date
      --  ,slrrasg_bldg_code
        ,stvbldg_desc         Hall
  from  stvbldg
        ,stvascd
        ,stvartp
        ,slrrasg  a
        ,slbrmap
  where 1 = 1 
  and   stvbldg_code        =  slrrasg_bldg_code
  and   stvascd_code        =  a.slrrasg_ascd_code
  and   stvartp_code        =  slbrmap_artp_code 
  and   a.slrrasg_term_code = (select min(b.slrrasg_term_code)
                               from slrrasg b
                               where b.slrrasg_term_code >= slbrmap_from_term
                               and   b.slrrasg_pidm = a.slrrasg_pidm)
  and   a.slrrasg_pidm      = slbrmap_pidm
  and   slbrmap_from_term   = p_term_code_entry --'201410'
  and   slbrmap_pidm        = p_pidm --948717
  union
  select stvartp_desc         contract_type
        --,slbrmap_artp_code
        ,SLBRMAP_ADD_DATE      application_date
     --   ,a.slrrasg_ascd_code
        ,'~'                   offer_status
        ,null                  offer_date
      --  ,slrrasg_bldg_code
        ,'~'                   Hall
  from  stvartp
        ,slbrmap
  where 1 = 1 
  and   stvartp_code        =  slbrmap_artp_code 
  and not exists (select 'Y'
                  from slrrasg  a
                  where 1 = 1
                  and   a.slrrasg_term_code = (select min(b.slrrasg_term_code)
                                               from slrrasg b
                                               where b.slrrasg_term_code >= slbrmap_from_term
                                               and   b.slrrasg_pidm = a.slrrasg_pidm)
                  and   a.slrrasg_pidm      = slbrmap_pidm)
  and   slbrmap_from_term   = p_term_code_entry --'201410'
  and   slbrmap_pidm        = p_pidm;  

  cursor get_status_c is
  select sarappd_apdc_code
         ,sarappd_apdc_date
         ,stvapdc_desc
         ,SARAPPD_SEQ_NO 
  from   stvapdc
        ,sarappd
  where 1 = 1
  and   stvapdc_code            = sarappd_apdc_code
  and   not exists  (select 'X'
                     from skvssdt
                     where 1 = 1 
                     and   SKVSSDT_SDAT_CODE_ATTR   = 'WF_PRE_DECISION_EXCLUDE'
                     and   SKVSSDT_SDAT_CODE_ENTITY = 'AGENT'
                     and   SKVSSDT_SDAT_CODE_OPT_1  = sarappd_apdc_code)
 -- and   sarappd_apdc_code       not in ('RR','OE','TC','T2','T3','IR','VR','DR')  -- need to change this over to the SKASSDT mapping once set-up
  and   sarappd_appl_no         = p_appno
  and   sarappd_term_code_entry = p_term_code_entry
  and   sarappd_pidm            = p_pidm
  and   l_embargo_active        = 'N'
  union
  select sarappd_apdc_code
         ,sarappd_apdc_date
         ,stvapdc_desc
         ,SARAPPD_SEQ_NO 
  from   stvapdc
        ,sarappd
  where 1 = 1
  and   stvapdc_code            = sarappd_apdc_code
  and   not exists  (select 'X'
                     from skvssdt
                     where 1 = 1 
                     and   SKVSSDT_SDAT_CODE_ATTR   = 'WF_PRE_DECISION_EXCLUDE'
                     and   SKVSSDT_SDAT_CODE_ENTITY = 'AGENT'
                     and   SKVSSDT_SDAT_CODE_OPT_1  = sarappd_apdc_code)
 -- and   sarappd_apdc_code       not in ('RR','OE','TC','T2','T3','IR','VR','DR')  -- need to change this over to the SKASSDT mapping once set-up
  and   sarappd_appl_no         = p_appno
  and   sarappd_term_code_entry = p_term_code_entry
  and   sarappd_pidm            = p_pidm
  and   sarappd_apdc_date       < l_embargo_start_date
  and   l_embargo_active         = 'Y'
  order by 4 desc;

  cursor get_documents_c is
  select sarchkl_admr_code
       ,stvadmr_desc
       ,SARCHKL_CKST_CODE    
       ,sarchkl_receive_date
 --      ,SARCHKL_COMMENT item_desc
       , case when nvl(sarchkl_comment,etvdtyp_desc) like 'BDM%' then etvdtyp_desc
           else nvl(sarchkl_comment,etvdtyp_desc)
         end document_desc
  from  etvdtyp
       ,esblink
       ,stvadmr
       ,sarchkl
  where etvdtyp_code            = esblink_dtyp_code
  and   esblink_admr_code       = sarchkl_admr_code  
  and   stvadmr_disp_web_ind    = 'Y'
  and   stvadmr_code            = sarchkl_admr_code
  and   sarchkl_term_code_entry = p_term_code_entry --'201610'
  and   sarchkl_appl_no         = p_appno --2
  and   sarchkl_pidm            = p_pidm;
 
--- taken from mdx_bwskopay_pkg.mdx_at_dep_payment_p
   CURSOR gtvsdax_extc (
      gtv_int_code   GTVSDAX.GTVSDAX_INTERNAL_CODE%TYPE,
      gtv_grp_code   GTVSDAX.GTVSDAX_INTERNAL_CODE_GROUP%TYPE
   )
   IS
      SELECT GTVSDAX_EXTERNAL_CODE
        FROM GTVSDAX
       WHERE GTVSDAX_INTERNAL_CODE = gtv_int_code
         AND GTVSDAX_INTERNAL_CODE_GROUP = gtv_grp_code;


  cursor tbraccd_charges_c (p_pidm        spriden.spriden_pidm%type
                           ,p_term_code_entry   sgbstdn.sgbstdn_term_code_ctlg_1%type)
  is
-- jmp start june 2016
  select decode(tbbdetc_type_ind,'P','C',tbbdetc_type_ind) -- 1 tbraccd charges
       , tbbdetc_dcat_code                                 -- 2
       , ttvdcat_desc                                      -- 3
       , mdx_twbifnd_fund_code                             -- 4
       , nvl(mdx_twbifnd_web_pay,'N') mdx_twbifnd_web_pay  -- 5
       , sum (tbraccd_amount)         amount               -- 6
       , sum (tbraccd_balance)        balance              -- 7
       , 0                            deposit
  from   mdx_twbifnd
       , ttvdcat
       , tbbdetc
       , tbraccd
  where  tbbdetc_dcat_code  = mdx_twbifnd.mdx_twbifnd_category_code(+)
  and    tbbdetc_dcat_code   = ttvdcat_code
  and    tbbdetc_detail_code = tbraccd_detail_code
  and    tbbdetc_dcat_code   in ('CSH')
  and    tbraccd_pidm        = p_pidm
--  and    tbraccd_term_code  >= p_term_code_entry
  and    tbraccd_term_code  between p_term_code_entry-99 and p_term_code_entry
  group by tbbdetc_type_ind
         , tbbdetc_dcat_code
         , ttvdcat_desc
         , mdx_twbifnd_fund_code
         , mdx_twbifnd_web_pay
  having sum(tbraccd_balance) <> 0
  UNION
  select decode(tbbdetc_type_ind,'P','C',tbbdetc_type_ind) -- 1 tbraccd charges
       , tbbdetc_dcat_code                                 -- 2
       , ttvdcat_desc                                      -- 3
       , mdx_twbifnd_fund_code                             -- 4
       , nvl(mdx_twbifnd_web_pay,'N') mdx_twbifnd_web_pay  -- 5
       , sum (tbraccd_amount)         amount               -- 6
       , sum (tbraccd_balance)        balance              -- 7
       , 0                            deposit
  from   mdx_twbifnd
       , ttvdcat
       , tbbdetc
       , tbraccd
  where  tbbdetc_dcat_code  = mdx_twbifnd.mdx_twbifnd_category_code(+)
  and    tbbdetc_dcat_code   = ttvdcat_code
  and    tbbdetc_detail_code = tbraccd_detail_code
  and    tbbdetc_dcat_code   in ('TUI')
  and    tbraccd_pidm        = p_pidm
  and    tbraccd_term_code  >= p_term_code_entry
  group by tbbdetc_type_ind
         , tbbdetc_dcat_code
         , ttvdcat_desc
         , mdx_twbifnd_fund_code
         , mdx_twbifnd_web_pay
  having sum(tbraccd_balance) <> 0
-- jmp end june 2016
  union
  select decode(tbbdetc_type_ind,'P','C',tbbdetc_type_ind) -- 1 
       , tbbdetc_dcat_code                                 -- 2
       , ttvdcat_desc                                      -- 3
       , mdx_twbifnd_fund_code                             -- 4
       , nvl(mdx_twbifnd_web_pay,'N') mdx_twbifnd_web_pay  -- 5
       , sum (tbraccd_amount)     amount                   -- 6
       , abs(nvl(sum (tbraccd_balance),min(rego_exe.exempt_amount)))*-1  balance                  
       , 0                                                               deposit
  from   mdx_twbifnd
       , ttvdcat
       , tbbdetc
       , tbraccd        
       , (select sum(mdx_rego_exempt_amount) exempt_amount
          from   mdx_rego_exempt
          where  1 = 1
          -- ADM Nov 2016 Offer Letter changes - START  
          and mdx_rego_exempt_appl_no   = p_appno
          and   MDX_REGO_EXEMPT_TERM_CODE_FK = p_term_code_entry --p_term_code
          -- ADM Nov 2016 Offer Letter changes - END
          AND    mdx_rego_exempt_pidm      = p_pidm
          and    mdx_rego_exempt_term_code = p_term_code_entry ) rego_exe
  where  tbbdetc_dcat_code     = mdx_twbifnd.mdx_twbifnd_category_code(+)
  and    tbbdetc_dcat_code     = ttvdcat_code
  and    tbbdetc_detail_code   = tbraccd_detail_code (+)
  and    tbbdetc_dcat_code(+)  in ('EXM')
  and    tbraccd_pidm     (+)  = p_pidm
  and    tbraccd_term_code (+) >= p_term_code_entry
  group by tbbdetc_type_ind
         , tbbdetc_dcat_code
         , ttvdcat_desc
         , mdx_twbifnd_fund_code
         , mdx_twbifnd_web_pay 
  having abs(nvl(sum (tbraccd_balance),min(rego_exe.exempt_amount)))*-1 <> 0
  union
  select 'C'        --non-zero mdx_rego_tuition_fee        -- 1
       , mdx_twbifnd_category_code                         -- 2
       , ttvdcat_desc                                      -- 3
       , mdx_twbifnd_fund_code                             -- 4
       , nvl(mdx_twbifnd_web_pay,'N') mdx_twbifnd_web_pay  -- 5
       , mdx_rego_tuition_fee                              -- 6
       , mdx_rego_tuition_fee                              -- 7
       , mdx_rego_deposit deposit
  from   mdx_twbifnd
       , ttvdcat
       , mdx_rego_payment
  where  mdx_twbifnd_category_code = 'TUI'
  and    ttvdcat_code              = 'TUI'
  and    mdx_rego_tuition_fee     <> 0
  -- ADM Nov 2016 Offer Letter changes - START  
  and    mdx_rego_appl_no          = p_appno
  -- ADM Nov 2016 Offer Letter changes - END  
  and    mdx_rego_pidm             = p_pidm
  and    mdx_rego_admit_term_code  = p_term_code_entry
  and    not exists (  -- a tuition fee record in tbraccd
             select 1
             from   ttvdcat
                  , tbbdetc
                  , tbraccd
             where  1 = 1
             and    ttvdcat_code = 'TUI'
             and    tbbdetc_detail_code = tbraccd_detail_code
             and    tbbdetc_dcat_code   = 'TUI'
             and    tbraccd_pidm        = p_pidm
             and    tbraccd_term_code   >= p_term_code_entry
             group by tbbdetc_type_ind
                    , tbbdetc_dcat_code
                    , ttvdcat_desc )  
  order by 1,2 desc;   --

     --

  cursor check_data_exists_c ( p_pidm        spriden.spriden_pidm%type
                             , p_term_code_entry   sgbstdn.sgbstdn_term_code_ctlg_1%type)
  is
  select 'tsaarev'                 
  from   tbbdetc
       , tbraccd
  where  tbbdetc_detail_code = tbraccd_detail_code
  and    tbbdetc_dcat_code in ('TUI','CSH','EXM')
  and    tbraccd_pidm        = p_pidm
  and    tbraccd_term_code  >= p_term_code_entry 
  union
  select 'twarpay'                                     
  from   mdx_rego_payment
  where  mdx_rego_tuition_fee     <> 0
  -- ADM Nov 2016 Offer Letter changes - START
  and    mdx_rego_appl_no          = p_appno
  -- ADM Nov 2016 Offer Letter changes - END
  and    mdx_rego_pidm             = p_pidm
  and    mdx_rego_admit_term_code  = p_term_code_entry;

  cursor get_mapped_DEP_PAY_DIS is
  select SKVSSDT_TITLE
  from skvssdt
  where 1=1
  and   SKVSSDT_SDAT_CODE_ENTITY = 'ONLINEAP'
  and   SKVSSDT_SDAT_CODE_ATTR   = 'DEP_PAY_DISP'
  and   SKVSSDT_SDAT_CODE_OPT_1  =  l_dcat_maping_code;
--
-- jmp start june 2016
cursor get_term_desc is
select stvterm_desc
from   stvterm
where  STVTERM_CODE = p_term_code_entry; 
 -------------------------------------------------------------------------
 cursor get_comments_c is
 select *
 from saracmt
 where (substr(upper(saracmt_orig_code),1,2) = 'RO'
  -- ADM Nov 2016 Offer Letter changes - START    
        --or saracmt_orig_code = 'AGEN')
        or saracmt_orig_code IN ('AGEN','APPL'))
-- ADM Nov 2016 Offer Letter changes - END 
 and saracmt_appl_no   = p_appno
 and saracmt_term_code = p_term_code_entry
 and saracmt_pidm      = p_pidm
 order by saracmt_seqno desc;
 -- finace working out
/*cursor get_fee_details_c is
select mdx_rego_tuition_fee
       ,mdx_rego_deposit
from mdx_rego_payment
where 1 = 1
and   mdx_rego_admit_term_code = p_term_code_entry
and   mdx_rego_pidm            = p_pidm;


repeating table
select * 
from mdx_rego_exempt
where mdx_rego_exempt_pidm = 1018517


select tbbdetc_dcat_code
       ,ttvdcat_desc
       ,TBRACCD_AMOUNT
       ,TBRACCD_EFFECTIVE_DATE
from   ttvdcat
      ,tbbdetc
      ,tbraccd
where 1 = 1
and ttvdcat_code        = tbbdetc_dcat_code
and tbbdetc_detail_code = tbraccd_detail_code
and tbraccd_pidm        = 1018517 --:p_pidm 
and exists (select 'y' 
            from tbbdetc
            where tbbdetc_dcat_code  IN ('CSH','HCS')
            and tbbdetc_detail_code  = tbraccd_detail_code)
*/

   begin
      submit_btn := null;
      submit_btn2 := null;
      
      if msg is null then
         
        -- this will have to be the quals and published works parameters
         
           l_comment  := null;
          
      elsif msg is not null then
        
           l_comment  := p_comment;
        
      end if;   
      
     
      
       
    open get_ucas_embargo_dates_c;
    -- mdx adm start July 2016 
    -- so I do not have to alter the decision/action sql
    -- for creating the date+time swapped over to using an org varible for the to hold the gtvsdax entry
    fetch get_ucas_embargo_dates_c into l_embargo_org_start_date
                                       ,l_embargo_start_time
                                       ,l_embargo_org_end_date
                                       ,l_embargo_end_time;
    close get_ucas_embargo_dates_c;
    -- -- mdx adm end July 2016
    
    if (l_embargo_org_start_date is null
        and l_embargo_org_end_date is null)
        then
          l_embargo_active := 'N';
    end if;
    
    --l_con_start_date := trunc(l_embargo_start_date)||' 12:00';
    --l_con_end_date   := trunc(l_embargo_end_date)||' 17:00';
    
   -- mdx adm start July 2016
     
    --trunc(l_embargo_org_start_date)+substr(l_embargo_start_time,1,2)/24 + substr(l_embargo_start_time,3,2)/1400;
    -- DATE                           HOURS                   MINUTES
    /*select to_char(trunc(sysdate)+substr('1000',1,2)/24 + substr(1024,3,2)/1400,'DD-MON-YYYY hh24:mi')
      from dual
      returns
      08-JUL-2016 10:24
    */
    
     l_embargo_start_date := trunc(l_embargo_org_start_date)+substr(l_embargo_start_time,1,2)/24 + substr(l_embargo_start_time,3,2)/1400;
     l_embargo_end_date   := trunc(l_embargo_org_end_date)+substr(l_embargo_end_time,1,2)/24 + substr(l_embargo_end_time,3,2)/1400;
   
   -- need to double check the decision selection workds correctly with the time element added
   
 
    
--   if trunc(sysdate) between l_embargo_start_date and l_embargo_end_date
 --   if  sysdate between to_date(l_con_start_date,'dd-MON-yyyy HH:MI') AND to_date(l_con_end_date,'dd-MON-yyyy HH:MI')
  if sysdate between l_embargo_start_date and l_embargo_end_date  -- removing the trunc(sysdate) means it will look at the time element of the embargo dates
      then
        l_embargo_active := 'Y';
    end if;   
    
   --
     twbkwbis.p_opendoc ('mdx_agent_portal_pkg.mdx_agent_applicant_detail_p');
/*
   bwskalog.P_ProcLoginNon (
      in_id         => l_webid
      ,newid        => null
      ,pin          => l_web_pin
      ,newpin       => null
      ,verifypin    => null
      ,submit_btn   => null
--mdx jmp start July 2015
      ,lastname     => null
      ,firstname    => null
--mdx jmp end July 2015
   );
*/
           twbkfrmt.p_printheader(3, 
            '<font size=3 color = "red"><b>Application Information</b></font> ');
            
           htp.p('<form> <input type=submit value="Close Window" onclick="window.close()"> </form>');

       if trim(p_xceduz) <> '89KDFA7kjdJi368jSBo'
       then
           -- this is just an obsure hidden param set-up to make it harder to hack the page
           twbkwbis.p_dispinfo ('mdx_agent_portal_pkg.mdx_agent_applicant_detail_p','VALIDATION');
           
       else
       
           
          open get_login_details_c;
          fetch get_login_details_c into  l_webid
                                  ,l_web_pin;
          close get_login_details_c;
        
          twbkwbis.p_dispinfo ('mdx_agent_portal_pkg.mdx_agent_applicant_detail_p');  
          
      if msg is not null        
         then
              
           display_msg := ('Errors occurred.  Please try again.<ol>'||msg||'</ol>');
           
        --  bwskalog.msg.text := msg;
               bwskalog.msg.mlevel := 1;
                  bwskalog.msg.text :=
                    G$_NLS.Get ('X',
                  'SQL',display_msg)
                  ||HTF.br||bwskalog.msg.text;
      cell_msg_flag := 'Y';
      bwskalog.P_PrintMsg;
      cell_msg_flag := 'N';

      end if;
      
  --    HTP.formOpen ('mdx_agent_portal_pkg.mdx_agent_applicant_process_p','post');
        
       /*   
 

          htp.p ('Parameters passed into page' );
          htp.p ('<br>');
          htp.p ('<br>');    
           htp.p ('l_embargo_active = '||l_embargo_active);
          htp.p ('<br>');
          htp.p ('p_xceduz = '||p_xceduz);
          htp.p ('<br>');
          htp.p ('p_pidm   = '||p_pidm);  
          htp.p ('<br>');
          htp.p ('p_aidm   = '||p_aidm);    -- need to add aidm to the get_details_c in the list procedure      
          htp.p ('<br>');
          htp.p ('p_appno  = '||p_appno);  
          htp.p ('<br>');
          htp.p ('p_term_code_entry  = '||p_term_code_entry);  
          htp.p ('<br>');
          htp.p ('p_skrsain_source   = '||p_skrsain_source);  
          htp.p ('<br>');
          htp.p ('p_skrsain_applicant_no = '||p_skrsain_applicant_no );  
          htp.p ('<br>');
          htp.p ('p_app_type   = '||p_app_type);  
          htp.p ('<br>');
          htp.p ('____________________________________________________________');
          htp.p ('<br>');
          htp.p ('<br>');       
          */    

          open get_details_c (p_pidm
                              ,p_aidm
                              ,p_appno
                              ,p_skrsain_applicant_no
                              ,p_term_code_entry );
                                     
          fetch  get_details_c into  l_student_id 
                                     ,l_prefix    
                                     ,l_last_name     
                                     ,l_first_name    
                                     ,l_middle_name  
                                     ,l_email         
                                     ,l_skype_id        
                                     ,l_telephone
                                     ,l_regional_office
                                     ,l_prog_desc
                                     ,l_campus_desc
                                     ,l_term_code_entry_desc
                                     ,l_mode
                                     ,l_year
                                     ,l_agency_code
                                     ,l_birth_date
                                     ,l_ethnic_code
                                     ,l_ethnic_desc
                                     ,l_gender
                                     ,l_resd_code             
                                     ,l_country_perm_resd      
                                     ,l_birth_country         
                                     ,l_nationality            
                                     ,l_visa_req               
                                     ,l_passport_no          
                                     ,l_passport_issued  
                                     ,l_passport_expiry
                                     ,l_level_code     
                                     ,l_display_fee_section
                                     ,l_ro_email
                                     ,l_pre_sessional_required
                                     -- ADM Nov 2016 Offer Letter changes - START 
                                     ,l_offer_letter_exists;
                                     -- ADM Nov 2016 Offer Letter changes - END 
         close get_details_c;    
         
         if nvl(p_aidm,0) = 0 then
              
             open get_aidm_c;
             fetch get_aidm_c into l_aidm;
             close get_aidm_c;
             
         else
             l_aidm := p_aidm;
         end if;  
       
         ----------------------------------------------------------------------- 
          twbkfrmt.p_TableOpen('DATAENTRY' /*'DATADISPLAY'*/,CCAPTION=> 'Name:' );
        
          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledataheader('Applicant ID &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Title &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('First name &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Middle name &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Family name &nbsp;&nbsp;');
          twbkfrmt.p_tablerowclose;

          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledata(l_student_id);
          twbkfrmt.p_tabledata(l_prefix||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(l_first_name||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(l_middle_name||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(l_last_name||'&nbsp;&nbsp;');
          twbkfrmt.p_tablerowclose;          
          
                                                       
          twbkfrmt.p_tableclose;      

         -----------------------------------------------------------------------
          twbkfrmt.p_TableOpen('DATAENTRY' /*'DATADISPLAY'*/,CCAPTION=> 'Contact Details:' );
        
          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledataheader('Email &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Telephone no &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Skype ID&nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Permanent Address &nbsp;&nbsp;');    
          twbkfrmt.p_tablerowclose;

          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledata(l_email||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(l_telephone||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(l_skype_id||'&nbsp;&nbsp;');
                     
          l_address1        := null; 
          l_address2        := null; 
          l_address3        := null; 
          l_city            := null;
          l_postcode        := null;
          l_address_country := null;
          
          open get_address_c;
          fetch get_address_c into  l_address1 
                                   ,l_address2 
                                   ,l_address3 
                                   ,l_city 
                                   ,l_postcode; 
                                  -- ADM 09-NOV-2016 
                                  -- ,l_address_country; 
          close get_address_c;       
          
          -- ADM 09-NOV-2016
          -- added nvl's to not display where it is only a full-stop

          if nvl(l_address1,'.') <> '.' then
             l_address_string := l_address1||'&nbsp;&nbsp;<br>';
          end if;
          
          if nvl(l_address2,'.') <> '.' then
             l_address_string := l_address_string||l_address2||'&nbsp;&nbsp;<br>';
          end if;
          
          if nvl(l_address3,'.') <> '.' then
             l_address_string := l_address_string||l_address3||'&nbsp;&nbsp;<br>';
          end if;

          if nvl(l_city,'.') <> '.' then
             l_address_string := l_address_string||l_city||'&nbsp;&nbsp;<br>';
          end if;

          if nvl(l_postcode,'.') <> '.' then
             l_address_string := l_address_string||l_postcode||'&nbsp;&nbsp;<br>';
          end if;
/* -- ADM 09-NOV-2016 
   -- we don't actually use the country field to hold the country for overseas 
   -- addresses.  MISIS FAQ indicates we use the city to hold the country for overseas.
   
          if l_address_country is not null then
             l_address_string := l_address_string||l_address_country||'&nbsp;&nbsp;<br>';
          end if;
*/
          twbkfrmt.p_tabledata(l_address_string);
  
          twbkfrmt.p_tablerowclose;          
          
                                                       
          twbkfrmt.p_tableclose;   
          
   /* Users decided against using as they should use the Comments section to indicate changes are required
   if nvl(l_ro_email,'~') <> '~' then
          
             htp.p ('<br>');   
             
             htp.p ('<a href="mailto:'||l_ro_email||'?subject=Applicant ID: '||l_student_id||' Name: '||l_first_name||' '||l_last_name||'">Email Regional Office to update details</a>');
             
         --    htp.p ('Insert mailto link to the Regional Office:&nbsp;'||l_regional_office );
             htp.p ('<br>');
             
          end if;  */

         -----------------------------------------------------------------------

          twbkfrmt.p_TableOpen('DATAENTRY' /*'DATADISPLAY'*/,CCAPTION=> 'Course:' );
        
          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledataheader('Course &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Course commencement &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Campus &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Mode &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Year &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('UCAS <br> application &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Pre-sessional <br> requested? &nbsp;&nbsp;');
          

          twbkfrmt.p_tablerowclose;

          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledata(l_prog_desc||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(l_term_code_entry_desc||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(l_campus_desc||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(substr(l_mode,2)||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(l_year||'&nbsp;&nbsp;');
          
          if p_skrsain_source in ('U','G') 
            then
              twbkfrmt.p_tabledata('Y'||'&nbsp;&nbsp;');
          else
              twbkfrmt.p_tabledata('N'||'&nbsp;&nbsp;');
          end if;
          
          twbkfrmt.p_tabledata(l_pre_sessional_required||'&nbsp;&nbsp;');
          
          twbkfrmt.p_tablerowclose; 
          
          twbkfrmt.p_tableclose; 
          
         -----------------------------------------------------------------------

 
         twbkfrmt.p_TableOpen('DATAENTRY' /*'DATADISPLAY'*/,CCAPTION=> 'Status:' );
        
         twbkfrmt.p_tablerowopen;
         twbkfrmt.p_tabledataheader('Status Code&nbsp;&nbsp;');
         twbkfrmt.p_tabledataheader('Description &nbsp;&nbsp;');
         twbkfrmt.p_tabledataheader('Date &nbsp;');

         twbkfrmt.p_tablerowclose;
         
         open get_status_c;
         loop
         fetch get_status_c into l_status_code
                                ,l_status_date
                                ,l_status_desc
                                ,l_status_seqno ;
         exit when get_status_c%notfound;
         
 
            twbkfrmt.p_tablerowopen;
            twbkfrmt.p_tabledata(l_status_code||'&nbsp;&nbsp;');
            twbkfrmt.p_tabledata(l_status_desc||'&nbsp;&nbsp;');
            twbkfrmt.p_tabledata(to_char(l_status_date,'DD-MON-YYYY')||'&nbsp;&nbsp;');

            twbkfrmt.p_tablerowclose; 
            
            if l_status_code in ('C','CD','CF','CI') then
               l_get_offer := 'Y';
            end if;
          
            l_status_code  := null;
            l_status_desc  := null;
            l_status_date  := null;
            l_status_seqno := null;
            
            end loop;
          
          close get_status_c;
                    
          twbkfrmt.p_tableclose;               
          
--          if nvl(l_get_offer,'N') = 'Y'
          if nvl(p_offer,'0') <> '0'  -- only show the offer section if an offer has been made 
             then
               
               select skrudec_off_lib_string
               -- ADM Nov 2016 Offer Letter changes - START
                    --  ,substr(skrudec_exp_text,40)
                    ,ltrim(replace(substr(skrudec_exp_text,regexp_instr(skrudec_exp_text,'This offer is subject to your obtaining',1,1,1)),'<EOT>'))
               -- ADM Nov 2016 Offer Letter changes - END
               into   l_skrudec_off_lib_string
                     ,l_skrudec_exp_text
               from   skrudec               
               where skrudec_decn_seq = p_offer
               and   skrudec_pidm     = p_pidm;
             
               twbkfrmt.p_TableOpen('DATAENTRY' /*'DATADISPLAY'*/,CCAPTION=> 'Conditions of offer:' );
               twbkfrmt.p_tablerowopen;
               twbkfrmt.p_tabledata(l_skrudec_exp_text);
               twbkfrmt.p_tablerowclose;
               twbkfrmt.p_tableclose;                
          end if;          
       
      end if; -- check that validation passes 
      
      -------------------------------------------------------------------------
      -- ADM Nov 2016 Offer Letter changes - START
       if l_offer_letter_exists = 'Y' then
                     
                     HTP.formopen (twbkwbis.f_cgibin || 'bwskalog.P_ProcLoginNon', 'post','_blank');
                     htp.formHidden ('PAGE_ROUTE', 'OFFER_LETTER');
                     twbkfrmt.P_FormHidden ('in_id',l_webid);
                     twbkfrmt.P_FormHidden ('pin',l_web_pin); 
                     htp.formHidden ('NEWID', NULL);
                     htp.formHidden ('NEWPIN', NULL);
                     htp.formHidden ('VERIFYPIN', NULL);
                     htp.formHidden ('SUBMIT_BTN', NULL);
                     htp.formHidden ('p_appl_no', P_appno);
                     htp.formHidden ('p_term_code',P_term_code_entry);  
                        
                    if nvl(l_webid,'~') <> '~' then
                    
                        htp.br;
                        htp.p('<input type="submit" value="View offer letter"/>'); 
                        htp.br;
                    
                    end if;
                      
                    htp.formclose; 
                    
        end if;
      -- ADM Nov 2016 Offer Letter changes - END                  
      -----------------------------------------------------------------------      
   
      HTP.formopen (twbkwbis.f_cgibin || 'bwskalog.P_ProcLoginNon', 'post','_blank');
      htp.formHidden ('PAGE_ROUTE', 'AGENT_DOCUPLOAD');
      twbkfrmt.P_FormHidden ('in_id',l_webid);
      twbkfrmt.P_FormHidden ('pin',l_web_pin); 
      htp.formHidden ('NEWID', NULL);
      htp.formHidden ('NEWPIN', NULL);
      htp.formHidden ('VERIFYPIN', NULL);
      htp.formHidden ('SUBMIT_BTN', NULL);
      htp.formHidden ('p_appl_no', p_appno);
      htp.formHidden ('p_term_code',p_term_code_entry);     

         twbkfrmt.p_TableOpen('DATAENTRY' /*'DATADISPLAY'*/,CCAPTION=> 'Document status:' );
        
         twbkfrmt.p_tablerowopen;
         twbkfrmt.p_tabledataheader('Document Type &nbsp;&nbsp;');
         twbkfrmt.p_tabledataheader('Description &nbsp;&nbsp;');
         twbkfrmt.p_tabledataheader('Received date &nbsp;&nbsp;');

         twbkfrmt.p_tablerowclose;
         
         open get_documents_c;
         loop
         fetch get_documents_c into  l_sarchkl_admr_code
                                    ,l_stvadmr_desc 
                                    ,l_SARCHKL_CKST_CODE
                                    ,l_sarchkl_receive_date
                                    ,l_SARCHKL_COMMENT;
         exit when get_documents_c%notfound;
             
         
         /* no longer needed as the check for this is in the cursor    
            if l_sarchkl_comment like 'BDM%'
              then
                l_sarchkl_comment := '~';
            end if;  */
 
            twbkfrmt.p_tablerowopen;
            twbkfrmt.p_tabledata(l_stvadmr_desc||'&nbsp;&nbsp;');
            twbkfrmt.p_tabledata(NVL(l_SARCHKL_COMMENT,'~') ||'&nbsp;&nbsp;');
            twbkfrmt.p_tabledata(NVL(to_char(l_sarchkl_receive_date,'DD-MON-YYYY'),'Please upload </font>')||'&nbsp;&nbsp;');

            twbkfrmt.p_tablerowclose; 
          
            l_sarchkl_admr_code    := null;
            l_stvadmr_desc         := null;
            l_SARCHKL_CKST_CODE    := null;
            l_sarchkl_receive_date := null;
            l_SARCHKL_COMMENT      := null;
            
            end loop;
          
          close get_documents_c;
          
          -- ADM 07-NOV-2016 start
          -- added to only show the Document Upload button if a login exists
          if nvl(l_webid,'~') <> '~' then
          -- ADM 07-NOV-2016 end
          
            twbkfrmt.p_tablerowopen;        
          
          
 --         if nvl(l_aidm,0) <> 0 then
            
          --    l_string:= '<a href="mdx_doc_upload_pkg.mdx_doc_request_p?pidm='||p_pidm||'&term_code='||p_term_code||'&appl_no='||p_appno||'" style="color:red">'||l_my_action||'</a>';
            
            htp.p('<td></td><td></td><td>');       
                            
            HTP.formsubmit ('submit_btn','Document upload' );
            htp.p('</td>');
            
            
            
      /*      htp.p ('<td class="dedefault">
                    <a href="mdx_doc_upload_pkg.mdx_doc_request_p?pidm='||p_pidm||'&term_code='||p_term_code_entry||'&appl_no='||p_appno||'" target="_blank" >
                    <input type="submit" value="Document Upload"/>
                    </a></td>'); */
                    
            -- using submit allows it to use the MDX theme for the button        
          
   --       else
              
    --          htp.p ('<td class="dedefault">Unable to find a valid login for applicant portal - please contact Admissions </td>');
          
     --     end if;  
          
         twbkfrmt.p_tablerowclose;                 
         
         -- ADM 07-NOV-2016 start
         end if;
         -- ADM 07-NOV-2016 end
                    
          twbkfrmt.p_tableclose;     
        HTP.formclose;
      
         -----------------------------------------------------------------------
  if (l_level_code in ('UG','PG')
      and l_resd_code = 'O'
      and nvl(l_display_fee_section,'N') = 'Y')  -- decision code U, UF or DU = Y 
      
      then
      
-- The finance section has been lifted from the mdx_bwskopay_pkg with some
-- modification as the functionality to actually pay was not required here
-- we do need to look into how to do the payment

  open  gtvsdax_extc ('WEBDETCODE', 'WEBACCTSUM');
  fetch gtvsdax_extc 
  into  gtv_ext_code;
  close gtvsdax_extc;

  --
-- jmp start june 2016
  open get_term_desc;
  fetch get_term_desc into l_term_desc;
  close get_term_desc;
-- jmp end june 2016
  row_count := 0;

  twbkfrmt.p_TableOpen('DATAENTRY' /*'DATADISPLAY'*/,CCAPTION=> 'Fee and Payment Details:<br></br>');
  --

  -- Just check if there is any data to display

  l_fee_exists := 'N';

  for check_data_exists_r in check_data_exists_c (p_pidm, p_term_code_entry) loop 

    l_fee_exists := 'Y';

  end loop;

  if l_fee_exists = 'Y' then

--    htp.formhidden ('std_id', std_id); 
--
-- jmp start june 2016
 --   htp.formhidden ('p_pidm', p_pidm);
 --   htp.formhidden ('p_term', p_term_code_entry); 
-- jmp end june 2016
--

  --  htp.p ('<br></br>'); 
 --   htp.print('<font size=2 >&nbsp;<b>' || 'Fee and Payment Details' || '</b>&nbsp;</font>'); 

    htp.tablerowopen( 'left'
                       ,null
                       ,null
                       ,null
                       ,null);

    --

--    twbkfrmt.p_tabledataheader ('<font size=2><b>' || 'Category Code' || '</b></font>');

    twbkfrmt.p_tabledataheader ('<font size=2><b>' || 'Description' || '</b></font>');              

    twbkfrmt.p_tabledataheader ('<font size=2><b>' || 'Amount' || '</b></font>');

--    twbkfrmt.p_tabledataheader ('<font size=2><b>' || 'Web Payment' || '</b></font>');

    htp.tablerowclose;

    --------------------------------------------   

    for tbraccd_charges_r in tbraccd_charges_c (p_pidm, p_term_code_entry) loop 
--

      htp.tablerowopen;

      if tbraccd_charges_r.tbbdetc_dcat_code = 'TUI' then

        l_total_tui := tbraccd_charges_r.balance;
--
-- jmp start june 2016
--
      l_mapped_DEP_PAY_DIS := NULL;
      l_dcat_maping_code := tbraccd_charges_r.tbbdetc_dcat_code;
--
      open get_mapped_DEP_PAY_DIS;
      fetch get_mapped_DEP_PAY_DIS into l_mapped_DEP_PAY_DIS;
      close get_mapped_DEP_PAY_DIS;
--

----        l_ttvdcat_desc := tbraccd_charges_r.ttvdcat_desc;

	l_ttvdcat_desc  := l_mapped_DEP_PAY_DIS;
--
-- jmp end june 2016
--
        l_deposit   := tbraccd_charges_r.deposit;

        htp.formhidden ('dcode_tab', tbraccd_charges_r.tbbdetc_dcat_code);

	    htp.formhidden ('fund_tab', tbraccd_charges_r.mdx_twbifnd_fund_code);

        htp.formhidden ('desc_tab', tbraccd_charges_r.ttvdcat_desc);

        htp.formhidden ('bal_tab', tbraccd_charges_r.balance);

        htp.formhidden ('type_tab', 'balance');         

      elsif tbraccd_charges_r.tbbdetc_dcat_code = 'CSH' then

         l_total_csh := tbraccd_charges_r.balance;

      end if;  

      --l_total_outstanding := l_total_outstanding - abs(tbraccd_charges_r.balance) ;

      l_total_outstanding := l_total_outstanding + tbraccd_charges_r.balance ;

   -- twbkfrmt.p_tabledata (tbraccd_charges_r.tbbdetc_dcat_code||'&nbsp');
--
-- jmp start june 2016
      l_mapped_DEP_PAY_DIS := NULL;
--
      l_dcat_maping_code := tbraccd_charges_r.tbbdetc_dcat_code;
--
      l_mapped_DEP_PAY_DIS := NULL;
--
      open get_mapped_DEP_PAY_DIS;
      fetch get_mapped_DEP_PAY_DIS into l_mapped_DEP_PAY_DIS;
      close get_mapped_DEP_PAY_DIS;
--
      if l_mapped_DEP_PAY_DIS is NULL then
          twbkfrmt.p_tabledata (tbraccd_charges_r.ttvdcat_desc||'&nbsp');

      else
         twbkfrmt.p_tabledata (l_mapped_DEP_PAY_DIS||'&nbsp');
      end if;  
-- jmp end june 2016

    --  twbkfrmt.p_tabledata ( to_char (tbraccd_charges_r.balance, 'L999G999G999G990D99')||'&nbsp','right');

      htp.tableData( to_char (tbraccd_charges_r.balance, 'L999G999G999G990D99')||'&nbsp','right');

--      twbkfrmt.p_tabledata (tbraccd_charges_r.mdx_twbifnd_web_pay||'&nbsp','center');

      htp.tablerowclose;

    end loop;

    --

    htp.tableclose;    

    --  

    if l_deposit > 0 then

      l_deposit := l_deposit - abs(nvl(l_total_csh,0)) ;

    end if;



    -- only display if there is any fees are outstanding

      pay_count := 0;

    if nvl(l_total_outstanding,0) > 0 then

  

/*      twbkfrmt.p_tableopen ( 'DATAENTRY'
                             ,cattributes  => 'SUMMARY= "' ||
                                            g$_nls.get ('mdx_bwskopay_pkg-0001'
                             ,'SQL'
                             ,'This table contains Balance details.') || '"' ); */

      twbkfrmt.p_TableOpen('DATAENTRY' /*'DATADISPLAY'*/,CCAPTION=> 'Outstanding Fees:<br></br>');                            

        --
  --    htp.print('<font size=2 >&nbsp;<b>' || 'Outstanding Fees' || '</b>&nbsp;</font>');

      htp.tablerowopen ('left'
                         ,null
                         ,null
                         ,null
                         ,null);   

 

      twbkfrmt.p_tabledataheader ('<font size=2><b>' || 'Description' || '</b></font>');              

      twbkfrmt.p_tabledataheader ('<font size=2><b>' || 'Total Balance' || '</b></font>');

      if nvl(l_deposit,0) > 0 then

        twbkfrmt.p_tabledataheader ('<font size=2><b>' || 'Deposit Required' || '</b></font>');

      end if;

    --  twbkfrmt.p_tabledataheader ('<font size=2><b>' || 'Pay Amount' || '</b></font>');

      htp.tablerowclose;

      

      htp.tablerowopen ('left'
                         ,null
                         ,null
                         ,null
                         ,null);

--
      twbkfrmt.p_tabledata (l_ttvdcat_desc||'&nbsp');           

   --   twbkfrmt.p_tabledata ( to_char (l_total_outstanding, 'L999G999G999G990D99')||'&nbsp','right');

      htp.tableData( to_char (l_total_outstanding, 'L999G999G999G990D99')||'&nbsp','right');
--
-- jmp start june 2016
--      htp.formhidden ('tot_out',l_total_outstanding);
-- jmp end june 2016
-- 

      if nvl(l_deposit,0) > 0 then
     --   twbkfrmt.p_tabledata ( to_char (l_deposit, 'L999G999G999G990D99')||'&nbsp','right');
        htp.tableData ( to_char (l_deposit, 'L999G999G999G990D99')||'&nbsp','right');
      end if;

/*      

      pay_count := 1;
      row_count := 1;

       

      twbkwbis.p_tabledataopen;

			   web_pay_exists := web_pay_exists + 1;

			   

			    twbkfrmt.p_formlabel (
                  g$_nls.get ('BWLKEGR1-0600', 'SQL', 'Pay'),
                  visible   => 'INVISIBLE',
                  idname    => 'pay_id' || to_char (row_count));



				  twbkfrmt.p_formtext (
                  'pay_tab',
                  12,
                  12,
                  l_amt,

				  cattributes  => 'ID="pay_id'||to_char(row_count)||'" onblur="chknum(this)");'); 

*/				  

      twbkwbis.p_tabledataclose;

      twbkfrmt.p_tablerowclose;      

      htp.tablerowclose;

      htp.tableclose;    


    end if;

--        twbkwbis.p_closedoc (curr_release);

  else

    twbkfrmt.p_printmessage ( g$_nls.get (
                    'BWSKOAC1-0037',
                    'SQL',
                    'No financial information can be found for this applicant. &nbsp Please contact <a href="mailto:AdmTech@mdx.ac.uk">AdmTech@mdx.ac.uk</a> quoting the applicants Middlesex ID who will be able to resolve this issue.' ),'WARNING');
-- check what they want for the Agent portal - already changed message slightly

      htp.tableclose;  
      
    end if;

  end if; -- display fee section
         -----------------------------------------------------------------------
   open get_accom_c;
   fetch get_accom_c into l_accom_contract_type
                         ,l_accom_application_date
                         ,l_accom_offer_status
                         ,l_accom_offer_date
                         ,l_accom_hall;
   close get_accom_c; 
   
   
   twbkfrmt.p_TableOpen('DATAENTRY' /*'DATADISPLAY'*/,CCAPTION=> 'Accommodation:' );

   twbkfrmt.p_tablerowopen; 
   
   if nvl(l_accom_contract_type,'~') <> '~' 
      then
      
          twbkfrmt.p_tablerowopen; 
          twbkfrmt.p_tabledataheader('Contract type: &nbsp;&nbsp;');
          twbkfrmt.p_tabledata(nvl(l_accom_contract_type,'~')||'&nbsp;&nbsp;');
          twbkfrmt.p_tablerowclose; 
          
          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledataheader('Application date: &nbsp;&nbsp;');
          twbkfrmt.p_tabledata(NVL(to_char(l_accom_application_date,'DD-MON-YYYY'),'~')||'&nbsp;&nbsp;');
          twbkfrmt.p_tablerowclose; 
          
          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledataheader('Offer status: &nbsp;&nbsp;');
          twbkfrmt.p_tabledata(nvl(l_accom_offer_status,'~')||'&nbsp;&nbsp;');
          twbkfrmt.p_tablerowclose; 
 
          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledataheader('Offer date: &nbsp;&nbsp;');
          twbkfrmt.p_tabledata(NVL(to_char(l_accom_offer_date,'DD-MON-YYYY'),'~')||'&nbsp;&nbsp;');
          twbkfrmt.p_tablerowclose; 
          
          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledataheader('Hall: &nbsp;&nbsp;');
          twbkfrmt.p_tabledata(nvl(l_accom_hall,'~')||'&nbsp;&nbsp;');
          twbkfrmt.p_tablerowclose;   
          
   else
    
    twbkfrmt.p_tablerowopen;   
    twbkfrmt.p_tabledata ('Applicant has not applied for accommodation.');
    twbkfrmt.p_tablerowclose; 

   end if;
                                
   twbkfrmt.p_tableclose; 


         -----------------------------------------------------------------------
     -- COMMENT DISPLAY
     
     l_comment_rec := null;
          
        twbkfrmt.p_TableOpen('DATAENTRY' /*'DATADISPLAY'*/,CCAPTION=> 'Comment history:' );
        
         twbkfrmt.p_tablerowopen;
         twbkfrmt.p_tabledataheader('Comment &nbsp;&nbsp;');
         twbkfrmt.p_tabledataheader('Date &nbsp;&nbsp;');
         twbkfrmt.p_tabledataheader('Whom? &nbsp;&nbsp;');

         twbkfrmt.p_tablerowclose;
         
         open get_comments_c;
         loop
         fetch get_comments_c into l_comment_rec;
         exit when get_comments_c%notfound;
         
 
            twbkfrmt.p_tablerowopen;
            
            twbkfrmt.p_tabledata(l_comment_rec.saracmt_comment_text||'&nbsp;&nbsp;');
            twbkfrmt.p_tabledata(NVL(to_char(l_comment_rec.saracmt_activity_date,'DD-MON-YYYY'),'~')||'&nbsp;&nbsp;');
            twbkfrmt.p_tabledata(l_comment_rec.saracmt_orig_code||'&nbsp;&nbsp;');
            
            twbkfrmt.p_tablerowclose; 
           
            l_comment_rec := null;
                        
            end loop;
          
          close get_comments_c;
                              
          twbkfrmt.p_tableclose;         
      
     
     
     -- COMMENT ENTRY    
         
      HTP.formOpen ('mdx_agent_portal_pkg.mdx_agent_applicant_process_p','post'); -- moved up the page
      -- send the params onto the processing page so they can be passed back after the add
      twbkfrmt.P_FormHidden ('in_id',l_webid);
      twbkfrmt.P_FormHidden ('pin',l_web_pin); 
      twbkfrmt.P_FormHidden ('p_xceduz',p_xceduz);
      twbkfrmt.P_FormHidden ('p_pidm',p_pidm);
      twbkfrmt.P_FormHidden ('p_aidm',p_aidm);
      twbkfrmt.P_FormHidden ('p_appno',p_appno); -- OA = sarahead_appl_seqno , NOA = saradap_appl_seqno
      twbkfrmt.P_FormHidden ('p_term_code_entry',p_term_code_entry);
      twbkfrmt.P_FormHidden ('p_skrsain_source',p_skrsain_source); 
      twbkfrmt.P_FormHidden ('p_skrsain_applicant_no',p_skrsain_applicant_no);
      twbkfrmt.P_FormHidden ('p_app_type',p_app_type);     
      twbkfrmt.P_FormHidden ('p_agency',l_agency_code); 
      twbkfrmt.P_FormHidden ('p_agent_id',p_agent_id); 
   
      submit_btn := null;
      
     twbkfrmt.p_TableOpen('DATAENTRY'/*,CCAPTION=> 'Enter comment:'*/);

     twbkfrmt.p_TablerowOpen;

        twbkfrmt.p_Tabledatalabel(twbkfrmt.f_formlabel ('Add comment: <br><p style="font-size:70%; font-weight:lighter">(4000 chars)</p>',
                                                         idname  => 'p_comment id="p_comment"'));
         twbkfrmt.p_tabledataopen (
            HTF.formtextareaopen2 (
               'p_comment',--'ud' || TO_CHAR (cquestion_index),
               '5',   -- this will give 6 rows displayed
               '110', -- this will give 100 chars displayed
               cattributes   => 'ID = "' || 'p_comment' || '"'
            ),
            ccolspan   => ccolspan
           -- ,cattributes      => 'width="70"'
         );
        
        if l_comment is not null then
        
            twbkfrmt.p_printtext (l_comment);
            
        end if;

         HTP.formtextareaclose;
      
      twbkfrmt.p_tabledataclose;     

      twbkfrmt.p_TablerowClose; 
      twbkfrmt.p_TablerowOpen; 
      htp.p('<td></td><td>'); 
      HTP.formsubmit ('submit_btn','Add' );
      htp.p('</td>');
      twbkfrmt.p_TablerowClose; 
     
     twbkfrmt.p_tableclose;     
     HTP.formClose;
         -----------------------------------------------------------------------

          twbkfrmt.p_TableOpen('DATAENTRY' /*'DATADISPLAY'*/,CCAPTION=> 'Personal information:' );
        
          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledataheader('DOB &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Gender &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Ethnic origin &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Disablity &nbsp;&nbsp;');   

          twbkfrmt.p_tablerowclose;

          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledata(to_char(l_birth_date,'DD-MON-YYYY')||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(l_gender||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(l_ethnic_desc||'&nbsp;&nbsp;');
         
          
          open get_disability_c;
          loop
          fetch get_disability_c into l_sprmedi_medi_code
                                     ,l_stvmedi_desc;
          exit when get_disability_c%notfound;
          
             l_disability_list := l_disability_list||l_stvmedi_desc||'<br>';
          
             l_sprmedi_medi_code := null;
             l_stvmedi_desc      := null;
          
          end loop;
          
          close get_disability_c;
                      
          twbkfrmt.p_tabledata(nvl(l_disability_list,'No disability supplied')||'&nbsp;&nbsp;<br>');
          
          twbkfrmt.p_tablerowclose; 
          
          
          twbkfrmt.p_tableclose; 
          
         -----------------------------------------------------------------------         

          twbkfrmt.p_TableOpen('DATAENTRY' /*'DATADISPLAY'*/,CCAPTION=> 'Residency:' );
        
          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledataheader('Country of &nbsp;&nbsp;<br> permanent &nbsp;&nbsp;<br> residence&nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Country &nbsp;&nbsp;<br> of birth &nbsp;&nbsp;');
          twbkfrmt.p_tabledataheader('Nationality &nbsp;&nbsp;'); 
          twbkfrmt.p_tabledataheader('Is a visa required &nbsp;&nbsp;<br> to study in the UK? &nbsp;&nbsp;'); 
          
          if l_visa_req = 'Y' then
          
             twbkfrmt.p_tabledataheader('Passport/travel &nbsp;&nbsp;<br> document number &nbsp;&nbsp;');
             twbkfrmt.p_tabledataheader('Country of &nbsp;&nbsp;<br> issue &nbsp;&nbsp;');
             twbkfrmt.p_tabledataheader('Expiry date &nbsp;&nbsp;');
             
          end if;

          twbkfrmt.p_tablerowclose;

          twbkfrmt.p_tablerowopen;
          twbkfrmt.p_tabledata(l_country_perm_resd||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(l_birth_country||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(l_nationality||'&nbsp;&nbsp;');
          twbkfrmt.p_tabledata(replace(replace(l_visa_req,'Y','Yes'),'N','No')||'&nbsp;&nbsp;');
 
           if l_visa_req = 'Y' then
          
             twbkfrmt.p_tabledata(l_passport_no||'&nbsp;&nbsp;');
             twbkfrmt.p_tabledata(l_passport_issued||'&nbsp;&nbsp;');
             twbkfrmt.p_tabledata(to_char(l_passport_expiry,'DD-MON-YYYY')||'&nbsp;&nbsp;');
          --   twbkfrmt.p_tabledata(l_passport_expiry||'&nbsp;&nbsp;');
             
          end if;
 
          
          twbkfrmt.p_tablerowclose; 
                    
          twbkfrmt.p_tableclose; 
         
         -----------------------------------------------------------------------
   --  htp.formSubmit('submit_btn2','Exit',cattributes=>'onClick="do_exit()"');
   
   htp.p('<br></br><form> <input type=submit value="Close Window" onclick="window.close()"> ');
   
      twbkwbis.p_closedoc;
      
   end mdx_agent_applicant_detail_p;
-------------------------------------------------------------------------------
   PROCEDURE mdx_agent_portal_piggyback_p (p_xceduz              varchar2 -- note this is just a security param to make hacking page harder
                                          ,p_pidm                number   default null
                                          ,p_aidm                number   default null
                                          ,p_appno               number   default null
                                          ,p_term_code_entry     varchar2  default null
                                          ,p_skrsain_source      varchar2 default null
                                          ,p_skrsain_applicant_no varchar2 default null
                                          ,p_app_type            varchar2 default null
                                          ,p_offer               number default null)
   IS
   -- 
   l_webid    mdx_sabnstu.mdx_sabnstu_id%type;
   l_web_pin  mdx_sabnstu.mdx_sabnstu_pin%type;
   l_login_url  varchar2(500);
   --
   cursor get_login_details_c is
   SELECT mdx_sabnstu_id
         ,mdx_sabnstu_pin
   FROM mdx_sabnstu
   WHERE mdx_sabnstu_pidm = p_pidm
   union
   select sabnstu_id
         ,sabnstu_pin
   from sabnstu
   where sabnstu_aidm = p_aidm;
   --
   BEGIN
   
   -- login applicant to their account -  needed to open the Documents page
   l_webid    := null;
   l_web_pin  := null;
   
   open get_login_details_c;
   fetch get_login_details_c into  l_webid
                                  ,l_web_pin;
   close get_login_details_c;
   

 /*  l_login_url := 'bwskalog.P_ProcLoginNon?newid=&newpin=&in_id='||l_webid||'&pin='||l_web_pin||'&SUBMIT_BTN=&verifypin=';

   execute immediate l_login_url;*/
 
   
  bwskalog.P_ProcLoginNon (
      in_id         => l_webid
      ,newid        => null
      ,pin          => l_web_pin
      ,newpin       => null
      ,verifypin    => null
      ,submit_btn   => null
--mdx jmp start July 2015
      ,lastname     => null
      ,firstname    => null
--mdx jmp end July 2015
   );                                                      
 
     mdx_agent_portal_pkg.mdx_agent_applicant_detail_p  (p_xceduz 
                                                      ,p_pidm  
                                                      ,p_aidm 
                                                      ,p_appno
                                                      ,p_term_code_entry
                                                      ,p_skrsain_source
                                                      ,p_skrsain_applicant_no 
                                                      ,p_app_type
                                                      ,p_offer);
                                                      
    end mdx_agent_portal_piggyback_p;

-------------------------------------------------------------------------------
   PROCEDURE mdx_agent_applicant_process_p (p_xceduz             varchar2 -- note this is just a security param to make hacking page harder
                                          ,p_pidm                number    default null
                                          ,p_aidm                number    default null
                                          ,p_appno               number    default null
                                          ,p_term_code_entry     varchar2  default null
                                          ,p_skrsain_source      varchar2  default null
                                          ,p_skrsain_applicant_no varchar2 default null
                                          ,p_app_type            varchar2  default null
                                          ,p_offer               number    default null
                                          ,submit_btn            varchar2  default null
                                          ,p_comment             varchar2  default null
                                          ,p_agency              varchar2  default null
                                          ,p_agent_id            varchar2  default null
                                          ,PAGE_ROUTE            varchar2  default null
                                          ,submit_btn2           varchar2  default null
                                          ,in_id                 varchar2 default null
                                          ,pin                   varchar2 default null)
   IS
   -- 
   error_messages   varchar2(20000) default null;  -- made it this big for testing the large fields
   l_sqlerrm 		    varchar2(400); 
   l_user_id        saracmt.saracmt_user_id%type;
   l_comment_exists   char(1) default 'N';
   --
   cursor check_comment_exists_c is
   select distinct 'Y'
   from saracmt
   where 1 = 1
   and   saracmt_user_id              = p_agency||'_'||p_agent_id
   and   trunc(saracmt_activity_date) = trunc(sysdate)
   and   saracmt_comment_text         = p_comment
   and   saracmt_orig_code            = 'AGEN'
   and   saracmt_appl_no              = p_appno
   and   saracmt_term_code            = p_term_code_entry
   and   saracmt_pidm                 = p_pidm;
   --
   BEGIN
   
    error_messages := ('<li>SUBMIT_BTN          = '||submit_btn||
                       '<li>p_xceduz            = '||p_xceduz||
                       '<li>p_pidm              = '||p_pidm||
                       '<li>p_aidm              = '||p_aidm ||
                       '<li>p_appno             = '||p_appno ||
                       '<li>p_term_code_entry   = '||p_term_code_entry||
                       '<li>p_skrsain_source    = '||p_skrsain_source ||
                       '<li>p_app_type          = '||p_app_type||
                       '<li>p_offer             = '||p_offer||
                       '<li>p_comment           = '||p_comment||
                       '<li>p_agency            = '||p_agency||
                       '<li>p_agent_id          = '||p_agent_id||
                       '<li>in_id               = '||in_id||
                       '<li>pin                 = '||pin
                       );
                       
   error_messages := null;  -- comment this out if you want to see what params passed to page
   
 -- if nvl(submit_btn2,'~') = 'Document upload'  then
   
   --   null;
   -- <a href="mdx_doc_upload_pkg.mdx_doc_request_p?pidm='||p_pidm||'&term_code='||p_term_code_entry||'&appl_no='||p_appno||'" target="_blank" >;
    
   /* mdx_doc_upload_pkg.mdx_doc_request_p (pidm      => p_pidm
                                         ,term_code => p_term_code_entry
                                         ,appl_no   => p_appno);   */              
     
     /*   mdx_agent_portal_pkg.mdx_agent_applicant_detail_p (p_xceduz               => p_xceduz             
                                                          ,p_pidm                 => p_pidm               
                                                          ,p_aidm                 => p_aidm                
                                                          ,p_appno                => p_appno              
                                                          ,p_term_code_entry      =>  p_term_code_entry
                                                          ,p_skrsain_source       => p_skrsain_source    
                                                          ,p_skrsain_applicant_no => p_skrsain_applicant_no
                                                          ,p_app_type             => p_app_type         
                                                          ,p_offer                => p_offer
                                                          ,in_id                  => null
                                                          ,pin                    => null
                                                          ,msg                    => null            
                                                          ,p_agent_id             => p_agent_id
                                                          ,p_comment              => null);    */
                                                          
       
 --  else
   
   if nvl(submit_btn,'~') = '~' then  -- this just stops reprocessing the insert
   
        mdx_agent_portal_pkg.mdx_agent_applicant_detail_p (p_xceduz               => p_xceduz             
                                                          ,p_pidm                 => p_pidm               
                                                          ,p_aidm                 => p_aidm                
                                                          ,p_appno                => p_appno              
                                                          ,p_term_code_entry      =>  p_term_code_entry
                                                          ,p_skrsain_source       => p_skrsain_source    
                                                          ,p_skrsain_applicant_no => p_skrsain_applicant_no
                                                          ,p_app_type             => p_app_type         
                                                          ,p_offer                => p_offer
                                                          ,in_id                  => null
                                                          ,pin                    => null
                                                          ,msg                    => null            
                                                          ,p_agent_id             => p_agent_id
                                                          ,p_comment              => null); 
  else   
     
      if nvl(submit_btn,'~') = 'Add' 
       then
       
       if nvl(p_comment,'~') = '~'
         then
            error_messages := error_messages||'<li>Added comment contains no text';
       end if;      

      if nvl(p_comment,'~') <> '~' then
 
           if nvl(lengthb(p_comment),0) > 4000 then

              error_messages := error_messages||'<li>Comment length limited to 4000 chars ('||nvl(lengthb (p_comment),0)||' characters entered ). Please amend comment entered.';   
           end if;

      end if; 
        
      if nvl(error_messages,'~') = '~' then
      
          l_comment_exists := 'N';
      
          open check_comment_exists_c;
          fetch check_comment_exists_c into l_comment_exists;
          close check_comment_exists_c;
          
          if l_comment_exists = 'N' then
          -- only do the insert if it hasn't been done before
          -- this test was added to deal with multiple refreshes of the page
          -- that was causing the same record to be inserted each refresh
          
          l_user_id := p_agency||'_'||p_agent_id; 
          
             insert into saracmt
               (saracmt_pidm                   
               ,saracmt_term_code       
               ,saracmt_appl_no                
               ,saracmt_seqno           
               ,saracmt_comment_text     
               ,saracmt_orig_code       
               ,saracmt_activity_date                   
               ,saracmt_user_id)
             values
               (p_pidm
               ,p_term_code_entry
               ,p_appno
               ,((select nvl(max(saracmt_seqno),0)
                     from saracmt
                     where saracmt_term_code = p_term_code_entry
                     and   saracmt_appl_no   = p_appno
                     and   saracmt_pidm      = p_pidm)+1)
               ,p_comment
               ,'AGEN'
               ,sysdate
               ,l_user_id); 
               
            end if;             

        mdx_agent_portal_pkg.mdx_agent_applicant_detail_p (p_xceduz               => p_xceduz             
                                                          ,p_pidm                 => p_pidm               
                                                          ,p_aidm                 => p_aidm                
                                                          ,p_appno                => p_appno              
                                                          ,p_term_code_entry      =>  p_term_code_entry
                                                          ,p_skrsain_source       => p_skrsain_source    
                                                          ,p_skrsain_applicant_no => p_skrsain_applicant_no
                                                          ,p_app_type             => p_app_type         
                                                          ,p_offer                => p_offer
                                                          ,in_id                  => null
                                                          ,pin                    => null
                                                          ,msg                    => null            
                                                          ,p_agent_id             => p_agent_id
                                                          ,p_comment              => null);     
 
 
      elsif error_messages is not null 
             then
          
        mdx_agent_portal_pkg.mdx_agent_applicant_detail_p (p_xceduz               => p_xceduz             
                                                          ,p_pidm                 => p_pidm               
                                                          ,p_aidm                 => p_aidm                
                                                          ,p_appno                => p_appno              
                                                          ,p_term_code_entry      =>  p_term_code_entry
                                                          ,p_skrsain_source       => p_skrsain_source    
                                                          ,p_skrsain_applicant_no => p_skrsain_applicant_no
                                                          ,p_app_type             => p_app_type         
                                                          ,p_offer                => p_offer
                                                          ,in_id                  => null
                                                          ,pin                    => null
                                                          ,msg                    => error_messages            
                                                          ,p_agent_id             => p_agent_id
                                                          ,p_comment              => p_comment);   
            
      end if;  
   
      end if; -- Add button 
   
    end if; -- submit_btn is null
    
 -- end if; -- submit_btn2
    
  end mdx_agent_applicant_process_p ;
-------------------------------------------------------------------------------

END  mdx_agent_portal_pkg;     
/
show errors
CREATE OR REPLACE PUBLIC SYNONYM mdx_agent_portal_pkg FOR mdx_agent_portal_pkg
/
grant EXECUTE ON mdx_agent_portal_pkg TO ban_default_m
/
GRANT EXECUTE ON mdx_agent_portal_pkg TO www2_user
/
GRANT EXECUTE ON mdx_agent_portal_pkg TO baninst1
/